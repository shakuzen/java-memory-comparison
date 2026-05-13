# Java Memory Comparison: AOT and Compact Object Headers (COH)

This repository provides a minimal, reproducible benchmark to demonstrate two memory footprint regressions observed when running Spring Boot applications on recent JDK versions.

The application is a standard Spring Boot 4.1.0-RC1 web application (generated via start.spring.io).

## The Regressions

1. **General Footprint Regression (JDK 25 vs JDK 27 EA)**
   The baseline memory usage (Resident Set Size, RSS) for a Spring Boot web application has noticeably increased between JDK 25 and JDK 27 EA.

2. **AOT + COH Footprint Penalty**
   While Compact Object Headers (`-XX:+UseCompactObjectHeaders`) successfully reduce memory footprint when running in standard JIT mode, combining COH with Ahead-of-Time (AOT) compilation and Class Data Sharing (CDS) actually *increases* the memory footprint compared to running AOT alone. This penalty is present in both JDK 25 and the latest JDK 27 EA builds.

## Prerequisites

- Docker

## Running the Benchmark

A script is provided to build a Docker image containing both JDK 25.0.3 and JDK 27 EA (build 21), and then run the benchmark suite inside the container.

```bash
./run-benchmark-in-docker.sh
```

The benchmark will:
1. Compile the Spring Boot application and generate AOT classes.
2. Run the application 10 times for each configuration.
3. Measure the RSS (in MB) and the startup time (in ms).
4. Output a summary table comparing the averages.

You can also run `./generate-summary.sh` locally at any time to re-generate the summary table from the existing `target/logs/results.csv` data without re-running the full benchmark suite.

## Benchmark Details

The benchmark tests the following configurations for both JDK 25 and JDK 27:

1. **Baseline**: `java -jar app.jar`
2. **AOT**: `java -XX:AOTCache=app.aot -jar app.jar`
3. **AOT + COH**: `java -XX:+UseCompactObjectHeaders -XX:AOTCache=app_coh.aot -jar app.jar`

*Note: The container restricts the application to 2 CPUs and a 2GB memory limit via Docker container limits (`--cpus=2 --memory=2g`). Modern JVMs are container-aware and will automatically respect these cgroup limits.*
