#!/bin/bash

set -e

# On Git Bash (MSYS) for Windows, disable automatic Unix-to-Windows path
# conversion when invoking docker.exe. Otherwise the bind-mount destination
# "/work" gets rewritten to a Windows path and benchmark.sh is not found
# inside the container. No effect on Linux or macOS.
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    export MSYS_NO_PATHCONV=1
fi

echo "Building Docker image..."
docker build -t java-memory-comparison .

echo "Running benchmark in Docker..."
docker run --rm --cpuset-cpus="0,1" --memory=2g -v "$(pwd):/work" java-memory-comparison ./benchmark.sh "$@"
