# Java Memory Comparison: AOT and Compact Object Headers (COH)

This repository provides a minimal, reproducible benchmark to demonstrate memory footprint regressions observed when running Spring Boot applications on recent JDK versions.

The application is a standard Spring Boot 4.1.0-RC1 web application (generated via start.spring.io).

## The Regressions

1. **General Footprint Regression (JDK 25 vs JDK 27 EA)**
   The memory usage (Resident Set Size, RSS) for a Spring Boot web application immediately after startup has significantly increased between JDK 25 and JDK 27 EA across tested configurations (see below). The increase is most significant in the default configuration with no command-line options.

2. **AOT + COH Footprint Penalty**
   While the Compact Object Headers feature (`-XX:+UseCompactObjectHeaders`) reduces memory footprint with otherwise default flags, combining COH with Ahead-of-Time (AOT) compilation and Class Data Sharing (CDS) slightly *increases* the memory footprint compared to running AOT without COH. This penalty is present in both JDK 25 and the latest JDK 27 EA builds.

**Update:** _#2 above may be noise within run-to-run variance._

## Prerequisites

- Docker

## Running the Benchmark

A script is provided to build a Docker image containing both JDK 25.0.3 and JDK 27 EA (build 21) and then run the benchmark suite inside the container.

```bash
./run-benchmark-in-docker.sh
```

The benchmark will:
1. Compile the Spring Boot application (`.mvnw clean package`) and [unpack the executable jar](https://docs.spring.io/spring-boot/reference/packaging/efficient.html).
2. Run the application 10 times for each configuration.
3. Measure the RSS (in MB) and the startup time (in ms).
4. Output a summary table.

## Benchmark Details

The benchmark tests the following configurations for both JDK 25 and JDK 27:

1. **No COH**: `java -XX:-UseCompactObjectHeaders -jar target/app/demo-0.0.1-SNAPSHOT.jar`
2. **COH**: `java -XX:+UseCompactObjectHeaders -jar target/app/demo-0.0.1-SNAPSHOT.jar`
3. **AOT**: `java -Dspring.aot.enabled=true -XX:-UseCompactObjectHeaders -XX:AOTCache=target/app/application_XX.aot -jar target/app/demo-0.0.1-SNAPSHOT.jar`
4. **AOT + COH**: `java -Dspring.aot.enabled=true -XX:+UseCompactObjectHeaders -XX:AOTCache=target/app/application_coh_XX.aot -jar target/app/demo-0.0.1-SNAPSHOT.jar`

*Note: The container restricts the application to 2 CPUs and a 2GB memory limit via Docker container limits (`--cpus=2 --memory=2g`).*
