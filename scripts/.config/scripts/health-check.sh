#!/bin/bash
# Quick health check for the entire environment

echo "=== Environment Health Check ==="
echo ""

# CLI Tools
echo "CLI Tools:"
for tool in eza bat fd rg dust duf fzf zoxide; do
  command -v $tool > /dev/null && echo "  ✓ $tool" || echo "  ✗ $tool (missing)"
done
echo ""

# Core Services
echo "Core Services:"
pgrep -x "AeroSpace" > /dev/null && echo "  ✓ AeroSpace running" || echo "  ✗ AeroSpace not running"
brew services list | rg -q "sketchybar.*started" && echo "  ✓ SketchyBar running" || echo "  ✗ SketchyBar not running"
pgrep -x "karabiner" > /dev/null && echo "  ✓ Karabiner running" || echo "  ✗ Karabiner not running"
echo ""

# Configuration Syntax
echo "Configuration Syntax:"
zsh -n ~/.config/zsh/.zshrc 2>&1 && echo "  ✓ Zsh config valid" || echo "  ✗ Zsh config has errors"
aerospace list-workspaces --all > /dev/null 2>&1 && echo "  ✓ AeroSpace config valid" || echo "  ✗ AeroSpace config invalid"
echo ""

# Workspace Integration
echo "Workspace Integration:"
aerospace list-workspaces --all | wc -l | xargs -I {} echo "  ✓ {} workspaces configured"
echo ""

# SSH Agent
echo "SSH Agent:"
pgrep -u "$USER" ssh-agent > /dev/null && echo "  ✓ SSH agent running" || echo "  ✗ SSH agent not running"
echo ""

# Version Managers
echo "Version Managers:"
command -v asdf > /dev/null && echo "  ✓ ASDF installed" || echo "  ✗ ASDF not installed"
command -v pnpm > /dev/null && echo "  ✓ PNPM installed" || echo "  ✗ PNPM not installed"
echo ""

echo "=== Health Check Complete ==="
