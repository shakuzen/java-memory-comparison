#!/bin/bash

if [ -n "$1" ]; then
    results_file="$1"
else
    # Find the most recent results.csv if no argument provided
    results_file=$(ls -t results/results_*.csv 2>/dev/null | head -n 1)
    if [ -z "$results_file" ]; then
        echo "Error: No results.csv found. Run the benchmarks first."
        exit 1
    fi
fi

echo "========================================"
echo "Summary of runs"
echo "========================================"

awk -F',' '
BEGIN {
    printf "%-30s\t%-25s\t%-25s\n", "Configuration", "RSS (MB) Avg [Min, Max]", "Startup (ms) Avg [Min, Max]"
    print "----------------------------------------------------------------------------------------"
}
NR>1 {
    key = "JDK " $2 " (AOT=" $3 ", COH=" $4 ")"
    count[key]++
    sum_rss[key] += $5
    sum_time[key] += $6
    
    if (count[key] == 1) {
        min_rss[key] = $5
        max_rss[key] = $5
        min_time[key] = $6
        max_time[key] = $6
    } else {
        if ($5 < min_rss[key]) min_rss[key] = $5
        if ($5 > max_rss[key]) max_rss[key] = $5
        if ($6 < min_time[key]) min_time[key] = $6
        if ($6 > max_time[key]) max_time[key] = $6
    }
}
END {
    # Print in a specific order
    keys[1] = "JDK 25 (AOT=false, COH=false)"
    keys[2] = "JDK 25 (AOT=false, COH=true)"
    keys[3] = "JDK 25 (AOT=true, COH=false)"
    keys[4] = "JDK 25 (AOT=true, COH=true)"
    keys[5] = "JDK 27 (AOT=false, COH=false)"
    keys[6] = "JDK 27 (AOT=false, COH=true)"
    keys[7] = "JDK 27 (AOT=true, COH=false)"
    keys[8] = "JDK 27 (AOT=true, COH=true)"
    
    for (i=1; i<=8; i++) {
        k = keys[i]
        if (count[k] > 0) {
            avg_rss = sum_rss[k] / count[k]
            avg_time = sum_time[k] / count[k]
            
            rss_str = sprintf("%6.2f [%.0f, %.0f]", avg_rss, min_rss[k], max_rss[k])
            time_str = sprintf("%6.2f [%.0f, %.0f]", avg_time, min_time[k], max_time[k])
            
            printf "%-30s\t%-25s\t%-25s\n", k, rss_str, time_str
        }
    }
}' "$results_file"
