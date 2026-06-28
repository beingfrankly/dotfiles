STOW := stow -v -d $(HOME)/.dotfiles -t $(HOME)

# Packages that need --no-folding (mixed tracked/generated content)
NO_FOLD := git karabiner nvim claude zsh

# Standard packages (tree folding is fine)
STANDARD := bat atuin lazygit lazydocker starship oh-my-posh eza scripts aerospace theme ghostty

ALL := $(STANDARD) $(NO_FOLD)

# Linux: standard packages (no macOS-GUI tools: aerospace, ghostty, karabiner)
LINUX_STANDARD := bat atuin lazygit lazydocker starship oh-my-posh eza scripts theme

# Linux: no-fold packages (no macOS-GUI tools: karabiner)
LINUX_NOFOLD := git nvim claude zsh

# OS-aware active package sets — Linux drops macOS-GUI packages automatically
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Linux)
  ACTIVE_STANDARD := $(LINUX_STANDARD)
  ACTIVE_NOFOLD := $(LINUX_NOFOLD)
else
  ACTIVE_STANDARD := $(STANDARD)
  ACTIVE_NOFOLD := $(NO_FOLD)
endif
ACTIVE_ALL := $(ACTIVE_STANDARD) $(ACTIVE_NOFOLD)

.PHONY: install install-linux uninstall restow list $(ALL)

install: ## Stow all packages (OS-aware: Linux skips macOS-GUI tools)
	$(STOW) $(ACTIVE_STANDARD)
	$(STOW) --no-folding $(ACTIVE_NOFOLD)
	git -C $(HOME)/.dotfiles config core.hooksPath .githooks

install-linux: ## Stow all Linux packages (no macOS-GUI tools: aerospace, ghostty, karabiner)
	$(STOW) $(LINUX_STANDARD)
	$(STOW) --no-folding $(LINUX_NOFOLD)
	git -C $(HOME)/.dotfiles config core.hooksPath .githooks

uninstall: ## Unstow all packages
	$(STOW) -D $(ACTIVE_ALL)

restow: ## Re-stow all packages (OS-aware; used by post-merge hook)
	$(STOW) -R $(ACTIVE_STANDARD)
	$(STOW) -R --no-folding $(ACTIVE_NOFOLD)

list: ## List all packages
	@echo "Standard: $(STANDARD)"
	@echo "No-fold:  $(NO_FOLD)"
	@echo "Active ($(UNAME_S)): $(ACTIVE_STANDARD) | $(ACTIVE_NOFOLD)"

# Per-package targets
bat atuin lazygit lazydocker starship oh-my-posh eza scripts aerospace theme ghostty:
	$(STOW) $@

git karabiner nvim claude zsh:
	$(STOW) --no-folding $@

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'
