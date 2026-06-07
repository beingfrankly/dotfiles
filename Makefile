STOW := stow -v -d $(HOME)/.dotfiles -t $(HOME)

# Packages that need --no-folding (mixed tracked/generated content)
NO_FOLD := git karabiner nvim claude zsh

# Standard packages (tree folding is fine)
STANDARD := bat atuin lazygit lazydocker starship oh-my-posh eza scripts aerospace theme ghostty

ALL := $(STANDARD) $(NO_FOLD)

.PHONY: install uninstall restow list $(ALL)

install: ## Stow all packages
	$(STOW) $(STANDARD)
	$(STOW) --no-folding $(NO_FOLD)
	git -C $(HOME)/.dotfiles config core.hooksPath .githooks

uninstall: ## Unstow all packages
	$(STOW) -D $(ALL)

restow: ## Re-stow all packages (useful after adding files)
	$(STOW) -R $(STANDARD)
	$(STOW) -R --no-folding $(NO_FOLD)

list: ## List all packages
	@echo "Standard: $(STANDARD)"
	@echo "No-fold:  $(NO_FOLD)"

# Per-package targets
bat atuin lazygit lazydocker starship oh-my-posh eza scripts aerospace theme ghostty:
	$(STOW) $@

git karabiner nvim claude zsh:
	$(STOW) --no-folding $@

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'
