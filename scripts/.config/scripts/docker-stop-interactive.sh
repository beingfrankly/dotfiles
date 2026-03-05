#!/bin/bash

# Interactive Docker Container Stop Tool
# Uses Gum for a polished CLI experience

set -euo pipefail

# Colors for styling
SUCCESS_COLOR="2"
ERROR_COLOR="1"
INFO_COLOR="4"
WARNING_COLOR="3"

# Check dependencies
check_dependencies() {
    local missing_deps=()

    if ! command -v gum &> /dev/null; then
        missing_deps+=("gum")
    fi

    if ! command -v docker &> /dev/null; then
        missing_deps+=("docker")
    fi

    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo "Error: Missing required dependencies: ${missing_deps[*]}"
        echo ""
        echo "Install instructions:"
        for dep in "${missing_deps[@]}"; do
            case $dep in
                gum)
                    echo "  - Gum: brew install gum"
                    ;;
                docker)
                    echo "  - Docker: https://www.docker.com/get-started"
                    ;;
            esac
        done
        exit 1
    fi
}

# Get running containers
get_running_containers() {
    # Format: CONTAINER_ID|IMAGE|STATUS|NAMES
    docker ps --format "{{.ID}}|{{.Image}}|{{.Status}}|{{.Names}}" 2>/dev/null
}

# Format container info for display
format_container_display() {
    local line="$1"
    IFS='|' read -r id image status name <<< "$line"

    # Truncate long image names
    if [ ${#image} -gt 40 ]; then
        image="${image:0:37}..."
    fi

    printf "%-12s %-43s %-20s %s\n" "$id" "$image" "$name" "$status"
}

# Main function
main() {
    # Show header
    gum style \
        --foreground "$INFO_COLOR" \
        --border rounded \
        --border-foreground "$INFO_COLOR" \
        --padding "0 2" \
        --margin "1 0" \
        "🐳 Interactive Docker Container Stop Tool"

    # Check dependencies
    check_dependencies

    # Get running containers
    gum spin --spinner dot --title "Fetching running containers..." -- sleep 0.5

    local containers
    containers=$(get_running_containers)

    if [ -z "$containers" ]; then
        gum style \
            --foreground "$WARNING_COLOR" \
            --border rounded \
            --padding "1 2" \
            "⚠ No running containers found"
        exit 0
    fi

    # Count containers
    local count
    count=$(echo "$containers" | wc -l | tr -d ' ')

    gum style \
        --foreground "$SUCCESS_COLOR" \
        --margin "0 0 1 0" \
        "Found $count running container(s)"

    # Prepare container list for selection
    local formatted_containers=()
    local container_ids=()

    # Add header
    local header
    header=$(printf "%-12s %-43s %-20s %s" "CONTAINER ID" "IMAGE" "NAMES" "STATUS")

    gum style \
        --bold \
        --foreground "$INFO_COLOR" \
        "$header"

    echo ""

    # Format containers for display and store IDs
    while IFS= read -r line; do
        IFS='|' read -r id image status name <<< "$line"
        container_ids+=("$id")

        # Truncate long values for display
        if [ ${#image} -gt 40 ]; then
            image="${image:0:37}..."
        fi
        if [ ${#name} -gt 20 ]; then
            name="${name:0:17}..."
        fi
        if [ ${#status} -gt 30 ]; then
            status="${status:0:27}..."
        fi

        formatted_containers+=("$(printf "%-12s %-43s %-20s %s" "$id" "$image" "$name" "$status")")
    done <<< "$containers"

    # Let user filter and select containers
    local selected
    selected=$(printf "%s\n" "${formatted_containers[@]}" | \
        gum filter \
            --placeholder "Type to filter containers... (Select with Enter)" \
            --prompt "❯ " \
            --height 15)

    if [ -z "$selected" ]; then
        gum style \
            --foreground "$WARNING_COLOR" \
            "No container selected. Exiting."
        exit 0
    fi

    # Extract container ID from selection (first field)
    local selected_id
    selected_id=$(echo "$selected" | awk '{print $1}')

    # Get full container details
    local container_name
    local container_image
    container_name=$(docker inspect --format '{{.Name}}' "$selected_id" | sed 's/\///')
    container_image=$(docker inspect --format '{{.Config.Image}}' "$selected_id")

    # Show selection summary
    echo ""
    gum style \
        --foreground "$WARNING_COLOR" \
        --border double \
        --border-foreground "$WARNING_COLOR" \
        --padding "1 2" \
        --margin "1 0" \
        "⚠ You are about to stop this container:

Container ID: $selected_id
Name: $container_name
Image: $container_image"

    # Confirm action
    if ! gum confirm "Stop this container?"; then
        gum style \
            --foreground "$INFO_COLOR" \
            "Operation cancelled."
        exit 0
    fi

    # Stop the container with spinner
    echo ""
    if gum spin --spinner dot --title "Stopping container $selected_id..." -- docker stop "$selected_id" > /dev/null 2>&1; then
        gum style \
            --foreground "$SUCCESS_COLOR" \
            --border rounded \
            --border-foreground "$SUCCESS_COLOR" \
            --padding "1 2" \
            --margin "1 0" \
            "✓ Container $selected_id stopped successfully"
    else
        gum style \
            --foreground "$ERROR_COLOR" \
            --border double \
            --border-foreground "$ERROR_COLOR" \
            --padding "1 2" \
            --margin "1 0" \
            "✗ Failed to stop container $selected_id"
        exit 1
    fi
}

# Run main function
main "$@"
