#!/usr/bin/env zsh
# Performance profiling script for zsh prompt
# Usage: source this file, then run commands to see timing

# Enable timing
export ZSH_PROF=1

# Track prompt rendering time
_prompt_perf_start() {
    typeset -gF _prompt_start_time=$EPOCHREALTIME
}

_prompt_perf_end() {
    if [[ -n "$_prompt_start_time" ]]; then
        local elapsed=$(( (EPOCHREALTIME - _prompt_start_time) * 1000 ))
        if (( elapsed > 50 )); then  # Only show if > 50ms
            print -P "%F{yellow}[Prompt: ${elapsed}ms]%f" >&2
        fi
        unset _prompt_start_time
    fi
}

# Track command execution time
_preexec_timer() {
    typeset -gF _cmd_start_time=$EPOCHREALTIME
}

_precmd_timer() {
    if [[ -n "$_cmd_start_time" ]]; then
        local elapsed=$(( (EPOCHREALTIME - _cmd_start_time) * 1000 ))
        if (( elapsed > 100 )); then  # Only show if > 100ms
            print -P "%F{cyan}[Command: ${elapsed}ms]%f" >&2
        fi
        unset _cmd_start_time
    fi
    _prompt_perf_end
}

add-zsh-hook precmd _precmd_timer
add-zsh-hook preexec _preexec_timer
add-zsh-hook preexec _prompt_perf_start

echo "Performance profiling enabled. Run commands to see timing."


