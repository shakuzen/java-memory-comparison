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
    print "Configuration\t\t\tAvg RSS (MB)\tAvg Startup (ms)"
    print "----------------------------------------------------------------"
}
NR>1 {
    key = "JDK " $2 " (AOT=" $3 ", COH=" $4 ")"
    count[key]++
    sum_rss[key] += $5
    sum_time[key] += $6
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
            printf "%-30s\t%6.2f\t\t%6.2f\n", k, avg_rss, avg_time
        }
    }
}' $results_file
