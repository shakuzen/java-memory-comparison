#!/bin/bash

set -e

echo "Building Docker image..."
docker build -t java-memory-comparison .

echo "Running benchmark in Docker..."
docker run --rm --cpus=2 --memory=2g -v $(pwd):/work java-memory-comparison ./benchmark.sh
