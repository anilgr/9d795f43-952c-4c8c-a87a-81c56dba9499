#!/bin/bash

echo "Fetching latest iOS runtime..."
RUNTIME=$(xcrun simctl list runtimes | grep -i 'iOS' | tail -n 1 | awk '{print $NF}')

if [ -z "$RUNTIME" ]; then
    echo "Could not find an iOS runtime."
    exit 1
fi

echo "Found runtime: $RUNTIME"

echo "Creating iPhone SE (3rd generation) simulator for tiny screen stress-testing..."
UUID_SE=$(xcrun simctl create "iPhone SE (Tiny Screen Test)" "com.apple.CoreSimulator.SimDeviceType.iPhone-SE-3rd-generation" "$RUNTIME")

if [ -n "$UUID_SE" ]; then
    echo "✅ Successfully created iPhone SE simulator (UUID: $UUID_SE)"
else
    echo "❌ Failed to create iPhone SE simulator."
fi

echo "Creating iPhone 16e simulator for modern standard screen testing..."
UUID_16E=$(xcrun simctl create "iPhone 16e (Standard Screen Test)" "com.apple.CoreSimulator.SimDeviceType.iPhone-16e" "$RUNTIME")

if [ -n "$UUID_16E" ]; then
    echo "✅ Successfully created iPhone 16e simulator (UUID: $UUID_16E)"
else
    echo "❌ Failed to create iPhone 16e simulator."
fi

echo "Done! You can now run your boot_ios_sim.sh script to boot them up."
