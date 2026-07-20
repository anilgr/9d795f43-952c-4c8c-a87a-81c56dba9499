#!/bin/bash

echo "Fetching available iOS simulators..."

# Get available iPhone/iPad devices
IFS=$'\n'
devices=($(xcrun simctl list devices available | grep -iE 'iphone|ipad' | sed -e 's/^[[:space:]]*//'))

if [ ${#devices[@]} -eq 0 ]; then
    echo "No available simulators found."
    exit 1
fi

echo "Select a simulator to boot:"
PS3="Enter choice: "
select device in "${devices[@]}"; do
    if [ -n "$device" ]; then
        # Extract the UUID from the string
        uuid=$(echo "$device" | grep -oE '[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}')
        if [ -n "$uuid" ]; then
            echo "Booting simulator ($uuid)..."
            xcrun simctl boot "$uuid"
            open -a Simulator
            break
        else
            echo "Failed to extract UUID from selection."
            exit 1
        fi
    else
        echo "Invalid selection. Please try again."
    fi
done
