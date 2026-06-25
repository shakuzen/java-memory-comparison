# Java Memory Footprint Comparison

This repository provides a minimal, reproducible benchmark to compare the memory footprint observed when running a Spring Boot application on recent JDK versions.

The application is a standard Spring Boot 4.1.0 web application (generated via start.spring.io).

## The Regression

**JDK 25 vs JDK 28 EA:**
The memory usage (Resident Set Size, RSS) for a Spring Boot web application immediately after startup has significantly increased between JDK 25 and JDK 28 EA across tested configurations (see below). The increase is most significant in the default configuration with no command-line options.

## Prerequisites

- Docker

## Running the Benchmark

A script is provided to build a Docker image containing both JDK 25.0.3 and JDK 28 EA and then run the benchmark suite inside the container.

```bash
./run-benchmark-in-docker.sh
```

By default, Compact Object Headers (COH) are tested using the JVM's out-of-the-box defaults (i.e. no COH JVM options are passed, meaning COH is disabled by default on JDK 25 and enabled by default on JDK 28). To run the full matrix comparing explicitly enabled vs disabled COH scenarios, pass the `--include-coh` option:

```bash
./run-benchmark-in-docker.sh --include-coh
```

The benchmark will:
1. Compile the Spring Boot application (`.mvnw clean package`) and [unpack the executable jar](https://docs.spring.io/spring-boot/reference/packaging/efficient.html).
2. Run the application 10 times for each active configuration.
3. Measure the RSS (in MB) and the startup time (in ms).
4. Output a summary table.

## Benchmark Details

The configurations tested vary based on the presence of the `--include-coh` flag:

### Default Configurations (without `--include-coh`)
Both JDK 25 and JDK 28 are run using their respective default COH behaviors:
1. **Baseline**: `java -jar target/app/demo-0.0.1-SNAPSHOT.jar`
2. **AOT**: `java -Dspring.aot.enabled=true -XX:AOTCache=target/app/application_default_XX.aot -jar target/app/demo-0.0.1-SNAPSHOT.jar`

### Explicit Configurations (with `--include-coh`)
Explicitly forces COH enabling/disabling to benchmark the impact across both JDKs:
1. **No COH**: `java -XX:-UseCompactObjectHeaders -jar target/app/demo-0.0.1-SNAPSHOT.jar`
2. **COH**: `java -XX:+UseCompactObjectHeaders -jar target/app/demo-0.0.1-SNAPSHOT.jar`
3. **AOT**: `java -Dspring.aot.enabled=true -XX:-UseCompactObjectHeaders -XX:AOTCache=target/app/application_XX.aot -jar target/app/demo-0.0.1-SNAPSHOT.jar`
4. **AOT + COH**: `java -Dspring.aot.enabled=true -XX:+UseCompactObjectHeaders -XX:AOTCache=target/app/application_coh_XX.aot -jar target/app/demo-0.0.1-SNAPSHOT.jar`

*Note: The container restricts the application to 2 CPUs and a 2GB memory limit via Docker container limits (`--cpus=2 --memory=2g`).*
