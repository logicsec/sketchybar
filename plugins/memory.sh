#!/usr/bin/env bash

# Get total physical memory in bytes
total_memory=$(sysctl -n hw.memsize)

# Get used memory via top command (in GB)
used_memory=$(top -l1 | awk '/PhysMem/ {print $2}' | sed 's/G//')

# Convert used memory from GB to bytes (1 GB = 1073741824 bytes)
used_memory_bytes=$(echo "$used_memory * 1073741824" | bc)

# Calculate percentage of memory used using bash
memory_percentage=$(( (used_memory_bytes * 100) / total_memory ))

# Set the label in SketchyBar
sketchybar --set $NAME label="${memory_percentage}%"