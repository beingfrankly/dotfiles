# JDTLS Improvement Plan (Revised)

## Context & Constraints

- **No Mason** — manual dependency management preferred
- **Maven focus** — Gradle support deferred
- **Monorepo** — multiple Spring Boot projects, per-project JDTLS isolation (correct approach)
- **Slow init** — workspace initialization is brutal, especially first open
- **Lombok + MapStruct** — both annotation processors in use, ordering matters

---

## Phase 1: Diagnostics Foundation

Establish visibility before making changes. Can't fix what you can't see.

### 1.1 Create health check module structure

**File**: `lua/plugins/java/health.lua`

**Task**: Create empty health check module that registers with `:checkhealth java`

**Acceptance**: `:checkhealth java` runs without error, shows placeholder message

---

### 1.2 Add JDTLS installation check

**Task**: Verify JDTLS directory exists at expected location

**Check**:
- Directory `~/.local/share/nvim/mason/packages/jdtls` OR custom path exists
- Report path being used

---

### 1.3 Add JDTLS launcher JAR check

**Task**: Find launcher JAR using glob pattern instead of hardcoded version

**Check**:
- `plugins/org.eclipse.equinox.launcher_*.jar` exists
- Report found version
- WARN if multiple versions found
- ERROR if none found

---

### 1.4 Add Java runtime check

**Task**: Verify Java is available and report version

**Check**:
- `java -version` succeeds
- Report Java version
- WARN if < Java 17 (JDTLS requirement)

---

### 1.5 Add Lombok JAR check

**Task**: Verify Lombok JAR exists at configured path

**Check**:
- File exists at `~/.local/share/nvim/lombok/lombok.jar` (or configured path)
- Report version if possible
- WARN with installation instructions if missing

---

### 1.6 Add MapStruct + Lombok binding check

**Task**: Verify annotation processor configuration is correct for MapStruct

**Check**:
- Look for `lombok-mapstruct-binding` in pom.xml (indicates proper setup)
- Verify `target/generated-sources/annotations` exists after build
- WARN if MapStruct detected but binding dependency missing
- INFO: Remind that Lombok must be declared before MapStruct in annotation processor order

---

### 1.7 Add java-debug bundle check

**Task**: Verify debug adapter bundle exists

**Check**:
- Directory `~/.local/share/nvim/java-debug/` exists
- JAR `com.microsoft.java.debug.plugin-*.jar` found
- ERROR with installation instructions if missing

---

### 1.8 Add vscode-java-test bundle check

**Task**: Verify test runner bundle exists

**Check**:
- Directory `~/.local/share/nvim/vscode-java-test/server/` exists
- At least one JAR present
- ERROR with installation instructions if missing

---

### 1.9 Add Maven check

**Task**: Verify Maven is available

**Check**:
- `mvn -version` succeeds
- Report Maven version
- Report Maven home

---

### 1.10 Add workspace directory check

**Task**: Report workspace status for current project

**Check**:
- Workspace directory path
- Whether `.metadata` exists (indicates previous initialization)
- Size of workspace directory (indicator of bloat)

---

## Phase 2: Path Robustness

Eliminate version-specific hardcoding that breaks on updates.

### 2.1 Create path resolver utility

**File**: `lua/plugins/java/paths.lua`

**Task**: Create module with functions to resolve paths using globs

**Functions**:
- `find_launcher_jar()` — glob for `org.eclipse.equinox.launcher_*.jar`
- `find_lombok_jar()` — check standard locations
- `find_debug_bundle()` — glob for debug plugin JAR
- `find_test_bundles()` — glob for test server JARs

---

### 2.2 Replace hardcoded launcher JAR path

**File**: `ftplugin/java.lua`

**Task**: Use `paths.find_launcher_jar()` instead of version-specific string

**Fallback**: Error with clear message if not found

---

### 2.3 Replace hardcoded Lombok path

**File**: `ftplugin/java.lua`

**Task**: Use `paths.find_lombok_jar()` with fallback locations

**Fallback**: Continue without Lombok, warn user

---

### 2.4 Replace hardcoded debug bundle paths

**File**: `ftplugin/java.lua`

**Task**: Use glob-based discovery for debug bundles

**Fallback**: Debug features disabled with clear message

---

### 2.5 Add startup validation

**File**: `ftplugin/java.lua`

**Task**: Validate critical paths before starting JDTLS

**Behavior**:
- If launcher JAR missing → error, don't start JDTLS
- If Lombok missing → warn, continue
- If debug bundles missing → warn, continue

---

### 2.6 Configure generated sources recognition

**File**: `ftplugin/java.lua`

**Task**: Ensure JDTLS recognizes MapStruct generated sources

**Configuration**:
```lua
settings = {
  java = {
    project = {
      sourcePaths = {
        "target/generated-sources/annotations"
      }
    }
  }
}
```

**Benefit**: Completions and navigation work for MapStruct-generated mapper implementations

---

## Phase 3: Debug Configurations

Enable debugging for common scenarios.

### 3.1 Add Spring Boot debug launch config

**File**: `lua/plugins/java/debug.lua` (or equivalent)

**Task**: Add DAP configuration that:
- Finds main class automatically
- Launches with debug agent enabled
- Supports Spring profiles via input prompt

---

### 3.2 Add test class debug command

**Task**: Create function to debug current test class

**Keybinding**: `<leader>tdc`

**Behavior**: Run current test class with debugger attached

---

### 3.3 Add test method debug command

**Task**: Create function to debug test method at cursor

**Keybinding**: `<leader>tdm`

**Behavior**: Run single test method with debugger attached

---

### 3.4 Add debug with custom args config

**Task**: Add DAP configuration that prompts for:
- JVM arguments
- Program arguments
- Environment variables

---

### 3.5 Document debug workflow

**Task**: Add comments/docs explaining:
- How to start debugging
- How to set breakpoints
- Common debug keybindings
- Troubleshooting steps

---

## Phase 4: Maven Integration

Build tool commands accessible from Neovim.

### 4.1 Create Maven runner module

**File**: `lua/plugins/java/maven.lua`

**Task**: Create module structure for Maven commands

**Functions**:
- `find_pom()` — locate nearest pom.xml
- `run_maven(goals)` — execute Maven with goals

---

### 4.2 Add Maven clean install command

**Command**: `:MavenInstall` or `<leader>jmi`

**Task**: Run `mvn clean install -DskipTests` in Snacks terminal

**Behavior**:
- Find nearest pom.xml
- Open terminal with command
- Support running from project root

---

### 4.3 Add Maven test command

**Command**: `:MavenTest` or `<leader>jmt`

**Task**: Run `mvn test` in Snacks terminal

---

### 4.4 Add Maven test single class command

**Command**: `:MavenTestClass` or `<leader>jmtc`

**Task**: Run `mvn test -Dtest=CurrentClassName`

**Behavior**: Extract class name from current buffer

---

### 4.5 Add Maven package command

**Command**: `:MavenPackage` or `<leader>jmp`

**Task**: Run `mvn package -DskipTests`

---

### 4.6 Add Maven clean command

**Command**: `:MavenClean` or `<leader>jmc`

**Task**: Run `mvn clean`

---

### 4.7 Add Maven generate-sources command

**Command**: `:MavenGenerate` or `<leader>jmg`

**Task**: Run `mvn generate-sources`

**Use case**: Regenerate MapStruct mappers after interface changes

---

### 4.8 Add Maven custom goals command

**Command**: `:Maven <goals>`

**Task**: Run `mvn <user-provided-goals>`

**Example**: `:Maven dependency:tree`

---

## Phase 5: Quality of Life

Small improvements that reduce friction.

### 5.1 Add JDTLS restart command

**Command**: `:JdtlsRestart`

**Task**: Stop current JDTLS client, restart for current buffer

**Behavior**:
- `vim.lsp.stop_client()`
- Short delay
- Re-trigger `ftplugin/java.lua`

---

### 5.2 Cache Google Style formatter locally

**Task**: Download formatter XML to dotfiles, reference local copy

**Location**: `~/.config/nvim/resources/google_java_style.xml`

**Benefit**: No network dependency on startup

---

### 5.3 Make java-extras debug conditional

**File**: `java-extras.lua`

**Task**: Check `vim.g.java_extras_debug` instead of hardcoding `true`

**Default**: `false` unless explicitly enabled

---

### 5.4 Improve Lombok missing warning

**Task**: Include installation instructions in warning message

**Content**:
```
Lombok not found. Install with:
  mkdir -p ~/.local/share/nvim/lombok
  curl -L -o ~/.local/share/nvim/lombok/lombok.jar https://projectlombok.org/downloads/lombok.jar
```

---

### 5.5 Add debug bundle installation instructions

**Task**: Create or document installation steps

**Content**:
```
# java-debug
cd ~/.local/share/nvim
git clone https://github.com/microsoft/java-debug
cd java-debug
./mvnw clean install

# vscode-java-test
cd ~/.local/share/nvim
git clone https://github.com/microsoft/vscode-java-test
cd vscode-java-test
npm install
npm run build-plugin
```

---

## Phase 6: Performance & Reliability (Future)

Deferred improvements for later consideration.

### 6.1 Investigate workspace init time

**Task**: Profile what's slow
- First open vs subsequent opens
- Is `.metadata` being reused?
- Are exclusion patterns configured?

---

### 6.2 Add memory configuration override

**Task**: Allow project-specific memory settings

**Approach**: Check for `.jdtls-memory` file or similar

---

### 6.3 Add project-specific config support

**Task**: Support `.nvim.lua` with `vim.secure.read()` for JDTLS overrides

---

### 6.4 Add Java snippets

**Task**: Create LuaSnip snippets for common patterns
- `@Test` method
- `@ParameterizedTest`
- `@Autowired` field
- Logger declaration
- Try-catch blocks

---

## Implementation Order

```
Phase 1 (Diagnostics)     ████████████████████  ~2-3 hours
    └─ 1.1 → 1.2 → 1.3 → 1.4 → 1.5 → 1.6 → 1.7 → 1.8 → 1.9 → 1.10

Phase 2 (Path Robustness) ████████████████      ~1-2 hours
    └─ 2.1 → 2.2 → 2.3 → 2.4 → 2.5 → 2.6

Phase 3 (Debug Configs)   ████████████          ~1-2 hours
    └─ 3.1 → 3.2 → 3.3 → 3.4 → 3.5

Phase 4 (Maven)           ████████████████████  ~2 hours
    └─ 4.1 → 4.2 → 4.3 → 4.4 → 4.5 → 4.6 → 4.7 → 4.8

Phase 5 (QoL)             ████████████          ~1 hour
    └─ 5.1 → 5.2 → 5.3 → 5.4 → 5.5

Phase 6 (Future)          ░░░░░░░░░░░░          Deferred
```

---

## Quick Reference: New Keybindings

| Keybinding | Command | Phase |
|------------|---------|-------|
| `<leader>tdc` | Debug test class | 3 |
| `<leader>tdm` | Debug test method | 3 |
| `<leader>jmi` | Maven install | 4 |
| `<leader>jmt` | Maven test | 4 |
| `<leader>jmtc` | Maven test class | 4 |
| `<leader>jmp` | Maven package | 4 |
| `<leader>jmc` | Maven clean | 4 |
| `<leader>jmg` | Maven generate-sources (MapStruct) | 4 |

---

## Quick Reference: New Commands

| Command | Description | Phase |
|---------|-------------|-------|
| `:checkhealth java` | Validate Java environment | 1 |
| `:JdtlsRestart` | Restart JDTLS for current buffer | 5 |
| `:Maven <goals>` | Run arbitrary Maven goals | 4 |
| `:MavenInstall` | `mvn clean install -DskipTests` | 4 |
| `:MavenTest` | `mvn test` | 4 |
| `:MavenTestClass` | `mvn test -Dtest=<class>` | 4 |
| `:MavenPackage` | `mvn package -DskipTests` | 4 |
| `:MavenClean` | `mvn clean` | 4 |
| `:MavenGenerate` | `mvn generate-sources` (MapStruct) | 4 |
