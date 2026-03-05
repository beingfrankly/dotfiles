#!/bin/bash

# Interactive Script Picker using Gum
# Allows choosing and executing scripts from ~/scripts directory

set -e

# Configuration
SCRIPTS_DIR="$HOME/scripts"
SCRIPT_ICON="📜"
SUCCESS_COLOR="2"   # Green
ERROR_COLOR="1"     # Red
INFO_COLOR="4"      # Blue
HEADER_COLOR="212"  # Pink

# Check if gum is installed
if ! command -v gum &> /dev/null; then
    echo "Error: gum is not installed"
    echo "Install with: brew install gum"
    exit 1
fi

# Check if scripts directory exists
if [ ! -d "$SCRIPTS_DIR" ]; then
    gum style --foreground "$ERROR_COLOR" --border double --padding "1 2" \
        "Error: $SCRIPTS_DIR directory not found"
    exit 1
fi

# Get list of scripts
SCRIPTS=()
while IFS= read -r line; do
    SCRIPTS+=("$line")
done < <(cd "$SCRIPTS_DIR" && fd -e sh -e bash -e zsh --type f | sort)

# Check if any scripts found
if [ ${#SCRIPTS[@]} -eq 0 ]; then
    gum style --foreground "$ERROR_COLOR" --border rounded --padding "1 2" \
        "No scripts found in $SCRIPTS_DIR"
    exit 1
fi

# Display header
clear
gum style \
    --foreground "$HEADER_COLOR" \
    --border rounded \
    --border-foreground "$HEADER_COLOR" \
    --padding "1 2" \
    --margin "1 0" \
    --bold \
    "$SCRIPT_ICON  Script Picker" \
    "" \
    "Select a script to execute from $SCRIPTS_DIR"

# Format script list with descriptions
SCRIPT_OPTIONS=()
for script in "${SCRIPTS[@]}"; do
    # Extract first comment line as description (if exists)
    DESCRIPTION=$(head -n 20 "$SCRIPTS_DIR/$script" | grep -E "^#[^!]" | head -n 1 | sed 's/^# *//' | cut -c1-50)

    if [ -n "$DESCRIPTION" ]; then
        SCRIPT_OPTIONS+=("$script - $DESCRIPTION")
    else
        SCRIPT_OPTIONS+=("$script")
    fi
done

# Let user choose a script
SELECTED=$(gum choose --height 15 --header "Available scripts:" "${SCRIPT_OPTIONS[@]}")

# Extract script name (remove description if present)
SCRIPT_NAME=$(echo "$SELECTED" | cut -d' ' -f1)
SCRIPT_PATH="$SCRIPTS_DIR/$SCRIPT_NAME"

# Show what will be executed
gum style \
    --foreground "$INFO_COLOR" \
    --border rounded \
    --padding "1 2" \
    --margin "1 0" \
    "Selected: $SCRIPT_NAME" \
    "Path: $SCRIPT_PATH"

# Confirm execution
if ! gum confirm "Execute this script?"; then
    gum style --foreground 3 --italic "Cancelled"
    exit 0
fi

echo ""

# Create a temporary wrapper to capture output
TEMP_OUTPUT=$(mktemp)
trap "rm -f $TEMP_OUTPUT" EXIT

# Execute the script with spinner and capture exit code
set +e
gum spin --spinner dot --title "Running $SCRIPT_NAME..." -- bash -c "bash '$SCRIPT_PATH' > '$TEMP_OUTPUT' 2>&1"
EXIT_CODE=$?
set -e

echo ""

# Show result
if [ $EXIT_CODE -eq 0 ]; then
    gum style \
        --foreground "$SUCCESS_COLOR" \
        --border rounded \
        --border-foreground "$SUCCESS_COLOR" \
        --padding "1 2" \
        "✓ Script completed successfully"
elif [ $EXIT_CODE -eq 130 ]; then
    # Exit code 130 = SIGINT (Ctrl+C)
    gum style \
        --foreground 3 \
        --border rounded \
        --border-foreground 3 \
        --padding "1 2" \
        --italic \
        "⚠ Script cancelled by user (Ctrl+C)"
elif [ $EXIT_CODE -eq 143 ]; then
    # Exit code 143 = SIGTERM
    gum style \
        --foreground 3 \
        --border rounded \
        --border-foreground 3 \
        --padding "1 2" \
        --italic \
        "⚠ Script terminated"
else
    gum style \
        --foreground "$ERROR_COLOR" \
        --border double \
        --border-foreground "$ERROR_COLOR" \
        --padding "1 2" \
        "✗ Script failed with exit code: $EXIT_CODE"
fi

# Ask if user wants to run another script
echo ""
if gum confirm "Run another script?"; then
    exec "$0"
fi
