#!/bin/bash

set -e

# Number of iterations
ITERATIONS=10

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
WORKSPACE_DIR=$(pwd)
mkdir -p "${WORKSPACE_DIR}/results" "${WORKSPACE_DIR}/logs"
results_file="${WORKSPACE_DIR}/results/results_${TIMESTAMP}.csv"
echo "run_idx,jdk,aot,coh,process_started_rss_mb,time_to_process_start_ms" > "$results_file"

echo "========================================"
echo "Building application (Once)"
echo "========================================"
export JAVA_HOME=/opt/jdk25
export PATH=$JAVA_HOME/bin:$PATH

echo "Building application with JDK 25..."
./mvnw clean package -DskipTests > /dev/null 2>&1

echo "Extracting application..."
# Extract the Spring Boot fat JAR to run the application directly from the filesystem.
# This avoids the memory overhead of the nested JAR classloader, which is important
# for optimal footprint when using AOT and CDS.
# See: https://docs.spring.io/spring-boot/reference/packaging/efficient.html
java -Djarmode=tools -jar target/demo-0.0.1-SNAPSHOT.jar extract --destination target/app

measure_run() {
    local run_idx=$1
    local jdk=$2
    local aot=$3
    local coh=$4
    local java_cmd=$5
    
    local log_file="${WORKSPACE_DIR}/logs/run_${jdk}_aot${aot}_coh${coh}_${run_idx}_${TIMESTAMP}.log"
    
    # Start the process in the background
    $java_cmd > "$log_file" 2>&1 &
    local pid=$!
    
    # Wait for the application to start
    local process_in_milliseconds=""
    local timeout_counter=0
    while [[ $timeout_counter -lt 100 ]]; do
        if grep -q "Started DemoApplication in" "$log_file"; then
            local process_in_seconds=$(grep -Po "Started DemoApplication in \K[0-9]+\.[0-9]+" "$log_file")
            process_in_milliseconds=$(awk "BEGIN {print int($process_in_seconds * 1000)}")
            break
        fi
        sleep 0.1
        timeout_counter=$((timeout_counter + 1))
    done
    
    if [[ -z "$process_in_milliseconds" ]]; then
        echo "Failed to start in time. Check $log_file"
        kill -9 $pid 2>/dev/null || true
        exit 1
    fi
    
    # Measure RSS
    local rss_in_bytes=$(ps -o rss= $pid)
    local rss_in_mb=$((rss_in_bytes / 1024))
    
    # Kill the process
    kill -9 $pid 2>/dev/null || true
    wait $pid 2>/dev/null || true
    
    # Record result
    echo "$run_idx,$jdk,$aot,$coh,$rss_in_mb,$process_in_milliseconds" >> "$results_file"
}

run_variant() {
    cd "${WORKSPACE_DIR}"
    local jdk_version=$1
    local java_home="/opt/jdk${jdk_version}"
    export JAVA_HOME=$java_home
    export PATH=$JAVA_HOME/bin:$PATH
    
    echo "========================================"
    echo "Running benchmarks for JDK ${jdk_version}"
    echo "========================================"

    java -version

    local jar_path="demo-0.0.1-SNAPSHOT.jar"
    
    cd "${WORKSPACE_DIR}/target/app"
    
    local aot_only_cmd="java -Dspring.aot.enabled=true"
    local aot_coh_cmd="java -Dspring.aot.enabled=true -XX:+UseCompactObjectHeaders"
    
    echo "Preparing AOT cache for JDK ${jdk_version} (No COH)..."
    $aot_only_cmd -Dspring.context.exit=onRefresh -XX:AOTMode=record -XX:AOTConfiguration=application_${jdk_version}.aotconf -jar $jar_path > /dev/null 2>&1
    $aot_only_cmd -XX:AOTMode=create -XX:AOTConfiguration=application_${jdk_version}.aotconf -XX:AOTCache=application_${jdk_version}.aot -jar $jar_path > /dev/null 2>&1
    
    echo "Preparing AOT cache for JDK ${jdk_version} (With COH)..."
    $aot_coh_cmd -Dspring.context.exit=onRefresh -XX:AOTMode=record -XX:AOTConfiguration=application_coh_${jdk_version}.aotconf -jar $jar_path > /dev/null 2>&1
    $aot_coh_cmd -XX:AOTMode=create -XX:AOTConfiguration=application_coh_${jdk_version}.aotconf -XX:AOTCache=application_coh_${jdk_version}.aot -jar $jar_path > /dev/null 2>&1
    
    for i in $(seq 1 $ITERATIONS); do
        echo -n "Run $i/$ITERATIONS... "
        
        # 1. Baseline (No AOT, No COH)
        measure_run "$i" "$jdk_version" "false" "false" "java -jar $jar_path"
        
        # 2. COH (No AOT, COH enabled)
        measure_run "$i" "$jdk_version" "false" "true" "java -XX:+UseCompactObjectHeaders -jar $jar_path"
        
        # 3. AOT (AOT enabled, No COH)
        measure_run "$i" "$jdk_version" "true" "false" "$aot_only_cmd -XX:AOTCache=application_${jdk_version}.aot -jar $jar_path"
        
        # 4. AOT + COH (AOT enabled, COH enabled)
        measure_run "$i" "$jdk_version" "true" "true" "$aot_coh_cmd -XX:AOTCache=application_coh_${jdk_version}.aot -jar $jar_path"
        
        echo "Done"
    done
}

run_variant "25"
run_variant "27"

cd "${WORKSPACE_DIR}"
./generate-summary.sh "$results_file"

