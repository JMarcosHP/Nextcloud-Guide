#!/usr/bin/env bash
# php-fpm-autocalculation script — Calculates average memory per process and PM settings based on the actual Hardware.
# Make sure your php-fpm service is running in your server before executing this script.

set -euo pipefail

# 1) Detect php-fpm process name via ps
PF_NAME=$(ps axc | grep -Eo 'php-fpm[0-9]+\.[0-9]+' | head -n1)
if [[ -z $PF_NAME ]]; then
  echo "Error: could not find php-fpm process via ps axc" >&2
  exit 1
fi

# 2) Compute average RSS per process (KB → MB)
AVG_RSS_KB=$(ps --no-headers -o rss -C "$PF_NAME" | awk '{ sum+=$1; count++ } END { print (count>0 ? int(sum/count) : 0) }')
if (( AVG_RSS_KB < 1 )); then
  echo "Error: no php-fpm workers found for $PF_NAME" >&2
  exit 1
fi
AVG_PROC_MB=$(( AVG_RSS_KB / 1024 ))

# 3) Gather system resources
RESERVE_MB=1024
TOTAL_RAM_MB=$(awk '/MemTotal/ {print int($2/1024)}' /proc/meminfo)
CPU_CORES=$(nproc)
USABLE_MB=$(( TOTAL_RAM_MB - RESERVE_MB ))
(( USABLE_MB < AVG_PROC_MB )) && echo "Warning: usable RAM (${USABLE_MB}MB) < avg proc (${AVG_PROC_MB}MB)" >&2

# 4) Calculate pm.* values
MAX_CHILDREN=$(( USABLE_MB / AVG_PROC_MB ))
(( MAX_CHILDREN < 1 )) && MAX_CHILDREN=1
PM_MIN_SPARE=$CPU_CORES
PM_MAX_SPARE=$(( CPU_CORES * 2 ))
# Initial start_servers: 75% of CPU cores
START_SERVERS=$(( CPU_CORES * 3 / 4 ))
# Clamp start_servers between min_spare and max_spare
if (( START_SERVERS < PM_MIN_SPARE )); then
  START_SERVERS=$PM_MIN_SPARE
elif (( START_SERVERS > PM_MAX_SPARE )); then
  START_SERVERS=$PM_MAX_SPARE
fi

# 5) Print configuration snippets
cat <<EOF
; ----- PHP-FPM tuning -----
; Detected process      : $PF_NAME
; Avg memory per process: ${AVG_PROC_MB} MB

; === Dynamic mode (variable load) ===
pm = dynamic
pm.max_children     = $MAX_CHILDREN
pm.start_servers    = $START_SERVERS
pm.min_spare_servers= $PM_MIN_SPARE
pm.max_spare_servers= $PM_MAX_SPARE

; === Static mode (high performance) ===
pm = static
pm.max_children     = $MAX_CHILDREN
; In static mode all children spawn at startup, no spare settings.
; Static mode provides better performance but uses more resources.
EOF
