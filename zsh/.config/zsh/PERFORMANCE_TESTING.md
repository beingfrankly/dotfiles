# Performance Testing Guide - Starship vs oh-my-posh

**Date:** 2025-10-31  
**Goal:** Measure and optimize shell prompt performance

## Quick Performance Test

### 1. Test Shell Startup Time

```bash
# Measure startup time
time zsh -i -c exit

# Expected after optimizations: < 200ms
```

### 2. Test Prompt Rendering Time

```bash
# Enable profiling temporarily
source ~/.config/zsh/profile-prompt.sh

# Then run:
cd ~/code
# Check the timing output in stderr

# Disable profiling
unset ZSH_PROF
```

### 3. Test Directory Change Speed

```bash
# Test with zoxide
time for i in {1..10}; do z ~/code; z ~; done

# Test with regular cd
time for i in {1..10}; do cd ~/code; cd ~; done
```

## Detailed Performance Analysis

### Enable Comprehensive Profiling

1. **Enable zsh profiling:**
   ```bash
   # In .zshrc, uncomment line 5:
   zmodload zsh/zprof
   
   # And uncomment line 236:
   zprof
   ```

2. **Restart shell and run:**
   ```bash
   exec zsh
   ```

3. **Check the profile output** - look for slow functions/modules

### Profile Starship Specifically

```bash
# Set debug mode temporarily
export STARSHIP_LOG=trace

# Run commands, check logs
# Look for slow modules in ~/.cache/starship/

# Disable debug
export STARSHIP_LOG=error
```

## Performance Benchmarks

### Before (oh-my-posh)
- **Startup time**: ~300-500ms
- **Prompt rendering**: ~50-150ms (varies by repo size)
- **Directory change**: ~100-300ms (with git status)

### After (Starship) - Expected
- **Startup time**: ~100-200ms
- **Prompt rendering**: ~10-50ms
- **Directory change**: ~20-80ms

## Common Performance Issues

### 1. Git Status Checks
**Problem:** Large repos take time to check git status  
**Solution:** Already optimized in `starship.toml`:
- `scan_timeout = 5ms` (reduced from 10ms)
- `ignore_submodules = true`
- Disabled git_metrics, git_commit, git_state

### 2. Language Version Detection
**Problem:** Checking for node/python/go versions on every prompt  
**Solution:** Already optimized in `starship.toml`:
- Only checks specific files (package.json, go.mod, etc.)
- No extension scanning

### 3. Direnv Hooks
**Problem:** direnv checks .envrc files on every directory change  
**Solution:** This is expected behavior, but can be optimized:
```bash
# Check if direnv is slow
time direnv allow .
```

### 4. Atuin History
**Problem:** Atuin syncs history on startup  
**Solution:** Already optimized - atuin is async

## Optimization Checklist

- [x] Switched from oh-my-posh to starship
- [x] Reduced starship scan_timeout to 5ms
- [x] Disabled slow git modules (metrics, commit, state)
- [x] Optimized language detection (files only, no extensions)
- [x] Set STARSHIP_LOG=error (reduces overhead)
- [x] Added performance profiling hooks
- [x] Optimized zoxide initialization

## Troubleshooting Slow Prompts

### If prompt is still slow:

1. **Check which modules are slow:**
   ```bash
   # Enable starship debug
   export STARSHIP_LOG=trace
   exec zsh
   # Check logs in ~/.cache/starship/
   ```

2. **Disable specific modules temporarily:**
   ```bash
   # In starship.toml, set:
   [module_name]
   disabled = true
   ```

3. **Check git repository size:**
   ```bash
   # Large repos = slower git status
   git count-objects -vH
   ```

4. **Profile individual components:**
   ```bash
   # Time starship itself
   time starship prompt
   
   # Time git status
   time git status --porcelain
   
   # Time language detection
   time node --version 2>/dev/null
   ```

## Expected Results

After switching to Starship with optimizations:
- ✅ **Faster startup**: ~50-70% improvement
- ✅ **Faster prompt**: ~60-80% improvement  
- ✅ **Faster directory changes**: ~70-90% improvement
- ✅ **Lower memory usage**: Starship is more efficient

## Rollback

If you want to revert to oh-my-posh:

```bash
# In .zshrc, replace starship section with:
if command -v oh-my-posh &> /dev/null; then
    eval "$(oh-my-posh init zsh --config $HOME/.config/theme/oh-my-posh.json)"
fi
```

But Starship should be significantly faster!


