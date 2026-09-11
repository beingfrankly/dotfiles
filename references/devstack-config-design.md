# devstack configuration design

## Recommendation

Use one user-level file, `~/.config/devstack/config.toml`, keyed by the same normalized git project identifier as Worktrunk. A service has exactly three important concepts:

1. `scope = "project"` or `scope = "worktree"`;
2. one selected runner, with one or more available runner implementations (`compose` or `process`);
3. one or more TCP readiness probes.

Project-scoped services name a lease. Worktree-scoped services do not. This makes the important constraint visible instead of trying to infer it every time a command runs.

The first version should not try to turn HFS into a per-worktree backend. Its fixed Compose project name, container names, ports, hostnames, and peer URLs make that impossible from an orchestration wrapper. For HFS, the backend is one leased project resource. Native JVM processes are an alternative way to run members of that same leased backend, primarily to reduce memory use; they are not independent per-worktree instances.

## Location, project identity, and merging

The only configuration file in v1 is:

```text
~/.config/devstack/config.toml
```

`devstack` resolves the current git worktree through `git rev-parse --show-toplevel` and derives the project key from the canonicalized `remote.origin.url`: scheme and user are removed, separators are normalized, and a trailing `.git` is removed. Thus `ssh://git@hfg.ghe.com/Striive/HFS.git` becomes `hfg.ghe.com/Striive/HFS`. The key comparison is case-sensitive because some forges have case-sensitive paths. A non-git project can set an explicit absolute `root` on its project entry, but supporting non-git trees need not complicate git resolution.

Merging follows the Worktrunk precedent:

- `[defaults]` is merged into the selected project.
- A project scalar replaces the default scalar.
- Named tables are merged by key, so project tables add to defaults and a table with the same name recursively overrides it.
- Arrays replace arrays; they do not concatenate. Concatenating arrays makes it too hard for an author to remove a default.
- Unknown keys and duplicate logical names are validation errors, not warnings.

There is no checked-in `.devstack.toml` in v1. A central config avoids adding local-machine port, workspace, and secret-path policy to every repository. A checked-in discovery manifest could be added later if several users actually need to share the same service inventory.

## Schema

The shape below is the complete intended v1 surface. Values in angle brackets are illustrative, not literal syntax.

```toml
schema-version = 1

[defaults]
ready-timeout = "120s"
ready-interval = "500ms"
stop-timeout = "15s"
lease-ttl = "120s"
lease-renew-every = "30s"

[projects."<normalized remote or local id>"]
# Only needed for a project that cannot be resolved from its git remote.
root = "/absolute/project/root"
default-services = ["db", "web"]

[projects."<id>".leases."<lease name>"]
provider = "herdr-workspace-token"
# This must be a stable coordination workspace shared by all worktrees.
workspace = "<herdr workspace>"
token = "devstack_owner"
owner = "{{ branch }}"
ttl = "120s"
renew-every = "30s"

[projects."<id>".services."<service name>"]
scope = "project"                 # or "worktree"
lease = "<lease name>"            # required iff scope is project
runner = "compose"                # selected runner name
depends-on = ["db"]               # optional; must be acyclic
missing-files-message = "Run ..." # optional diagnostic, never executed

[projects."<id>".services."<service name>".ports.http]
strategy = "fixed"                # fixed is normally for leased services
value = 8080

[projects."<id>".services."<service name>".ports.debug]
strategy = "allocate"             # allocated atomically on the local host
preferred = 5005
range = [15005, 15999]

[projects."<id>".services."<service name>".runners.compose]
kind = "compose"
files = ["docker-compose.yml"]
project-name = "{{ project_id | sanitize }}-{{ worktree_id | hash8 }}"
services = ["api"]                # omit to address the complete Compose app
env = { APP_PORT = "{{ port.http }}" }
required-env = ["OPTIONAL_ENV_NAME"]
required-files = [".env"]

[projects."<id>".services."<service name>".runners.native]
kind = "process"
cwd = "api"
argv = ["./mvnw", "spring-boot:run"]
env-files = ["../select-docker/.api.env"]
env = { PORT = "{{ port.http }}" }
required-env = []
required-files = []

[projects."<id>".services."<service name>".readiness.main]
kind = "tcp"
host = "127.0.0.1"
port = "http"                     # symbolic reference to a declared port
timeout = "180s"
interval = "500ms"
```

All paths and `cwd` values are relative to the current worktree root unless absolute. `argv` is always an argument vector and is never interpreted by a shell. If a command genuinely needs pipes, expansion, or conditionals, the project should expose a small script and name that script in `argv`; adding a shell mini-language to TOML would be both fragile and unsafe.

The deliberately small template vocabulary is:

- `repo_root`: current worktree root;
- `project_id`: normalized project key;
- `branch`: current branch, with detached HEAD rejected when it is used as a lease owner;
- `worktree_id`: stable identity derived from the canonical worktree path;
- `port.<name>`: allocated or fixed port value;
- filters `sanitize` and `hash8` only.

Templates are allowed only in documented string fields. Environment variables are not implicitly expanded in config; that prevents accidental dependence on whichever agent happens to invoke the command.

### Port semantics

A fixed port is reserved while its service is running. An allocated port is chosen under a local file lock, recorded in devstack state, and reused for that worktree when possible. Allocation checks both devstack reservations and an actual bind attempt. A Compose service can only use an allocated host port if its Compose file already accepts an environment substitution such as `${APP_PORT:-3000}:3000`; devstack does not rewrite YAML.

A worktree-scoped service with a fixed, published TCP port is a validation error because it is not actually safe across worktrees. The author must either make the port injectable and use `strategy = "allocate"`, or classify the service as project-scoped and lease it.

### Runner and lifecycle semantics

For `kind = "compose"`, devstack invokes Docker Compose with the configured files, project name, environment, and service names. It uses Compose inspection and labels for status. When stopping one configured service it stops only its named Compose services; when stopping an entire per-worktree Compose application it may use `down`. It also reads the resolved Compose model to discover `env_file` entries, so missing secret files can be reported before startup. `required-files` supplements those discovered files; it does not cause devstack to parse or copy secrets.

For `kind = "process"`, devstack starts a new process group, records its PID and start identity under the user state directory, sends `SIGTERM` to the group on stop, waits `stop-timeout`, then sends `SIGKILL` if needed. `env-files` are dotenv files loaded into that process only. Secret values never appear in devstack config or status output.

Every service must have at least one TCP readiness probe, and all configured probes must pass. Readiness is independent of runner type. `run` fails if the process exits before readiness or if the timeout expires. There is intentionally no log-regex readiness mode: log wording is not an interface and matching an old line can produce a false positive.

`runner` is an ordinary scalar, so changing a service from Compose to native is a one-line override. `devstack run service --runner native` may select another declared runner for that invocation without editing config. Only one runner for a logical service may be active at once.

## Worked example: HFS

This is a valid, intentionally small HFS slice rather than a fabricated inventory of all 24 containers. The configuration skill would enumerate the remaining Compose services using the same pattern. It demonstrates the relevant cases: a backend service with Compose/native alternatives, its dotenv, fixed application and debug ports, and a per-worktree Angular frontend with an allocated port.

```toml
schema-version = 1

[defaults]
ready-timeout = "120s"
ready-interval = "500ms"
stop-timeout = "20s"
lease-ttl = "120s"
lease-renew-every = "30s"

[projects."hfg.ghe.com/Striive/HFS"]
default-services = ["select-application", "login-frontend"]

[projects."hfg.ghe.com/Striive/HFS".leases.backend]
provider = "herdr-workspace-token"
workspace = "hfs"
token = "devstack_owner"
owner = "{{ branch }}"
ttl = "120s"
renew-every = "30s"

[projects."hfg.ghe.com/Striive/HFS".services.select-application]
scope = "project"
lease = "backend"
runner = "compose"
missing-files-message = "Run `go-hfs setup` with a valid AWS session; generated dotenv credentials expire after about 8 hours."

[projects."hfg.ghe.com/Striive/HFS".services.select-application.ports.http]
strategy = "fixed"
value = 8080

[projects."hfg.ghe.com/Striive/HFS".services.select-application.ports.debug]
strategy = "fixed"
value = 5005

[projects."hfg.ghe.com/Striive/HFS".services.select-application.runners.compose]
kind = "compose"
files = ["docker-compose.yml"]
project-name = "hfs"
services = ["select-application"]
required-files = ["select-docker/.select-application.select.loc.env"]

[projects."hfg.ghe.com/Striive/HFS".services.select-application.runners.native]
kind = "process"
cwd = "select-application"
argv = [
  "mvnd",
  "spring-boot:run",
  "-Dspring-boot.run.profiles=local",
  "-Dspring-boot.run.jvmArguments=-Xms2g -Xmx4g -agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:5005",
]
env-files = ["../select-docker/.select-application.select.loc.env"]

[projects."hfg.ghe.com/Striive/HFS".services.select-application.readiness.main]
kind = "tcp"
host = "127.0.0.1"
port = "http"
timeout = "300s"
interval = "1s"

[projects."hfg.ghe.com/Striive/HFS".services.login-frontend]
scope = "worktree"
runner = "native"

[projects."hfg.ghe.com/Striive/HFS".services.login-frontend.ports.http]
strategy = "allocate"
preferred = 4200
range = [4200, 4299]

[projects."hfg.ghe.com/Striive/HFS".services.login-frontend.runners.native]
kind = "process"
cwd = "."
argv = ["pnpm", "exec", "ng", "serve", "login", "--port", "{{ port.http }}"]

[projects."hfg.ghe.com/Striive/HFS".services.login-frontend.readiness.main]
kind = "tcp"
host = "127.0.0.1"
port = "http"
timeout = "180s"
interval = "1s"
```

The generated full HFS entry should put every backend container and every native backend alternative under the single `backend` lease. That includes services that do not themselves bind a conflicting port: hardcoded peer URLs and the fixed `hfs` Compose identity make the backend one failure domain. The four frontends can be worktree-scoped only if `ng serve --port` is sufficient for their callback URLs and cross-app navigation. If any frontend assumes its canonical fixed port elsewhere, it belongs under the lease too. The skill must test or ask this; it must not infer safety merely from “not in Docker.”

The config points at dotenv files in the active worktree and provides an actionable diagnostic. devstack should not copy, symlink, refresh, or centrally cache the 18 generated secret files. File presence also cannot prove that embedded AWS-derived credentials are still valid. Automatically managing an eight-hour AWS session is a separate credential-management problem and should remain `go-hfs setup`'s responsibility.

## Worked example: small Node/Compose project

Assume this repository's Compose file uses `name: ${COMPOSE_PROJECT_NAME:-notes}` and publishes PostgreSQL as `${POSTGRES_PORT:-5432}:5432`. Its web process accepts `--port`. Both services can therefore be isolated per worktree and need no lease.

```toml
schema-version = 1

[defaults]
ready-timeout = "90s"
ready-interval = "500ms"
stop-timeout = "10s"
lease-ttl = "120s"
lease-renew-every = "30s"

[projects."github.com/acme/notes"]
default-services = ["db", "web"]

[projects."github.com/acme/notes".services.db]
scope = "worktree"
runner = "compose"

[projects."github.com/acme/notes".services.db.ports.postgres]
strategy = "allocate"
preferred = 5432
range = [15432, 15531]

[projects."github.com/acme/notes".services.db.runners.compose]
kind = "compose"
files = ["compose.yaml"]
project-name = "notes-{{ worktree_id | hash8 }}"
services = ["db"]
env = { POSTGRES_PORT = "{{ port.postgres }}" }
required-files = [".env"]

[projects."github.com/acme/notes".services.db.readiness.main]
kind = "tcp"
host = "127.0.0.1"
port = "postgres"
timeout = "60s"
interval = "500ms"

[projects."github.com/acme/notes".services.web]
scope = "worktree"
runner = "native"
depends-on = ["db"]

[projects."github.com/acme/notes".services.web.ports.http]
strategy = "allocate"
preferred = 3000
range = [13000, 13999]

[projects."github.com/acme/notes".services.web.runners.native]
kind = "process"
cwd = "."
argv = ["pnpm", "dev", "--", "--port", "{{ port.http }}"]
env-files = [".env.local"]
env = { DATABASE_PORT = "{{ port.postgres }}" }

[projects."github.com/acme/notes".services.web.readiness.main]
kind = "tcp"
host = "127.0.0.1"
port = "http"
timeout = "90s"
interval = "500ms"
```

If the existing Compose file instead hardcodes `name: notes`, `container_name`, and `5432:5432`, the skill has two honest choices: ask to patch Compose so the values are injectable, or configure the Compose application as `scope = "project"` with a lease. Config alone cannot make a non-duplicable application duplicable.

## Lease model

Each named lease protects a set of project-scoped services. For HFS there should be one lease, `backend`; splitting it into per-service leases would imply concurrency that its fixed peer URLs and Compose identity do not allow.

The token record is the authority visible to agents:

```text
workspace: hfs
token:     devstack_owner=<branch>
TTL:       120 seconds, refreshed every 30 seconds
```

The configured workspace must be a stable coordination workspace, not “the current worktree's workspace”; otherwise contenders would read and write different records. The skill must discover or ask for this name.

The command behavior is:

- `devstack claim [lease]` acquires every required lease, or the named lease. It is idempotent for the configured owner. A tiny keeper process refreshes the Herdr token while the claim is held.
- `devstack run <service>` claims the service's lease if necessary, starts the selected runner, and waits for TCP readiness. If another owner holds the lease, it fails and prints that owner and remaining TTL. It never kills the other owner's process or containers.
- `devstack release [lease]` stops services that devstack recorded under this owner's lease, stops the keeper, and removes the token. It refuses to release a different owner's token. Forced takeover must be an explicit, visibly destructive option and should not be part of an agent's normal workflow.
- `devstack status` reports the lease owner and expiry, selected runner, process/container state, allocated ports, and readiness separately. “Running but not ready” is a real status.
- `devstack stop` obeys the same ownership check and stops services in reverse dependency order. It does not use broad container-name searches or kill arbitrary listeners on a port.

TTL metadata by itself is not a mutual-exclusion algorithm. The shown `herdr workspace report-metadata` operation appears to be a last-writer-wins update; two agents can both observe an empty token and both report ownership. Because devstack arbitrates services on one local machine, v1 should wrap the read/check/write/verify claim sequence in an OS file lock keyed by `(project id, lease name)`. The file lock is only a short atomicity guard; Herdr remains the durable, expiring ownership record. All devstack clients must follow this protocol. If Herdr offers an atomic compare-and-set operation, use it instead. Without either compare-and-set or the local lock, the lease design is unsafe and should not be shipped.

After taking the local lock, claim reads the token, rejects a live foreign owner, writes its owner with TTL, reads it back, and only then succeeds. The keeper renews well before expiry. A crashed owner loses its token after the TTL; a crashed process cannot leave a permanent lease. On release, devstack uses an actual Herdr token-delete operation if available; otherwise it reports the same token with the minimum TTL and waits for confirmed expiry before another claim succeeds.

Local runtime records should live below the platform user-state directory and be keyed by project, worktree, and service. They contain PIDs, process start identities, Compose coordinates, port reservations, and keeper PIDs—never environment values. PID reuse must be detected by comparing the recorded process start identity before signaling anything.

## Agent skill authoring workflow

The skill should be a conservative inventory-and-question workflow, not an autonomous service starter.

1. **Resolve the project.** Find the git root and common directory, normalize the origin remote, find any existing project entry, and validate that the selected entry is unambiguous.
2. **Inventory runners.** Parse `docker compose config` (prefer its JSON output), `package.json` scripts and workspace metadata, and Maven `pom.xml` modules/plugins. Record Compose service names, project/container names, published ports, `env_file` paths, dependencies, Node scripts, Spring Boot modules, profiles, and obvious port flags. Read Dockerfiles only when Compose points to them.
3. **Classify isolation.** Fixed `container_name`, a fixed Compose `name`, fixed published ports, shared volumes with mutable data, and hardcoded localhost/peer URLs are evidence for `scope = "project"`. Parameterized Compose project names and host ports are evidence that `scope = "worktree"` is possible. For HFS, scanning the 21 `application-local.yml` files and `/etc/hosts` evidence makes the whole backend one lease.
4. **Draft the smallest config.** Add only services the user actually runs, choose one default runner per service, add alternative runners only when both are useful, and add a TCP probe using the externally reachable listening port. Never put a secret value into TOML.
5. **Ask only for non-derivable decisions.** Present a compact list of uncertainties, apply the answers, and do not silently guess about ownership or readiness.
6. **Validate without starting.** Run schema validation, resolve all templates, check executable and path existence, inspect the resolved Compose model, verify named Compose services, check dependency cycles, and check static port/lease conflicts. Emit the exact commands that would run. Starting containers, logging into AWS, or probing a live port requires a separate explicit request.
7. **Write atomically and revalidate.** Preserve unrelated projects and user edits in the central TOML. Show the added/changed project entry and the final validation result.

### Realistically auto-derivable

- Project identifier, current worktree, branch, and common git repository.
- Compose files, service names, declared dependencies, project/container names, published ports, volumes, and `env_file` paths.
- Whether a Compose project name or published port is already parameterized.
- Node package-manager scripts and common `--port` conventions.
- Maven modules and explicit Spring Boot plugin/profile invocations found in repository scripts or documentation.
- Candidate TCP readiness ports from published ports or explicit server configuration.
- Missing dotenv files and executables.

### Must be asked or confirmed

- Which services belong in the everyday default stack rather than merely existing in Compose.
- Whether mutable data is intentionally shared, disposable, or must be per worktree.
- The stable Herdr coordination workspace and acceptable TTL.
- Whether a hardcoded service should be leased or whether the repository may be changed to parameterize it.
- Which of several ports means “usable,” especially when an app exposes HTTP, management, and debug ports.
- The supported native command, local profile, heap size, and debug policy when repository scripts do not already define them.
- How missing secret files are generated and what human authentication is required. The skill can record a diagnostic such as `Run go-hfs setup`; it must not invent or capture credentials.
- Whether alternate frontend ports are compatible with OAuth callbacks, CORS, cookies, and cross-app links.

Validation should reject a project-scoped service without a lease, a worktree-scoped service with a lease, unknown templates, missing readiness, an invalid Compose service, duplicate runner names, dependency cycles, an allocation range that contains no usable port, and `renew-every >= ttl / 2`. It should warn when multiple independently claimable leases expose the same fixed port or reuse the same hardcoded Compose project name, because those leases are not actually independent.

## Tradeoffs and pushback

### Keep

- **One central file and Worktrunk-style project keys.** This is familiar and keeps local policy local.
- **Explicit service scope.** It captures the primary fact devstack exists to manage.
- **Named lease groups.** HFS needs only one, but names cost little and allow another project to have, for example, an independently leased hardware simulator.
- **Compose and managed process runners only.** They cover HFS and the stated Node/Rails cases while giving devstack reliable status and stop behavior.
- **TCP readiness only.** It is runner-neutral and hard to fake accidentally.
- **Small port allocation.** Without it, “worktree-scoped” web servers with default ports immediately recreate the original conflict.

### Cut from v1

- Raw `docker run`, Kubernetes, arbitrary start/stop shell hooks, log matching, HTTP response assertions, process-pattern discovery, and plugin runner types.
- Secret generation, AWS session renewal, a secrets cache, or copying gitignored dotenv files between worktrees.
- Automatic rewriting of Compose, Angular, Spring, Rails, hosts files, or application YAML.
- Configuration profiles and inheritance beyond defaults plus one project. Selecting a declared runner is enough for the Compose/native HFS choice.
- Cross-machine leases. This is a local dev-stack tool; the short OS lock deliberately assumes all contenders share the host.
- Automatic forced takeover. Expiry is the normal crash-recovery path; overriding a live owner should require a human decision.

### Important contradictions to surface

Calling HFS frontends “not part of the singleton” does not automatically make them concurrently runnable: their Angular ports are fixed. They become per-worktree only when the port is overridden and the surrounding browser/OAuth/CORS assumptions tolerate that override. Otherwise they must be leased too.

Similarly, calling native HFS services “low-memory” does not make them per-worktree. They still use hardcoded peer URLs, fixed service and debug ports, and the same local infrastructure. Native versus container is a runner decision inside the backend lease, not a scope decision.

Finally, Herdr TTL tokens provide crash expiry but, based on the operation supplied, not atomic acquisition. The local claim lock (or a real Herdr compare-and-set primitive) is mandatory. Treating read-then-report as a lease would preserve exactly the race devstack is meant to eliminate.

This design intentionally solves the common 90%: identify the project, claim truly shared resources, launch Compose or a process, allocate ports for isolatable services, and verify TCP readiness. Anything more should be added only after a concrete repository cannot be represented this way.
