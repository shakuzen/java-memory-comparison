FROM ubuntu:24.04

RUN DEBIAN_FRONTEND=noninteractive apt-get update -y && apt-get install -y --no-install-recommends \
    curl ca-certificates && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /opt/jdk25 &&\
    cd /opt/jdk25 &&\
    case `uname -m` in aarch64) \
    curl -L "https://download.bell-sw.com/java/25.0.3+11/bellsoft-jdk25.0.3+11-linux-aarch64.tar.gz" | tar zx --strip-components=1 ;; \
    *) curl -L "https://download.bell-sw.com/java/25.0.3+11/bellsoft-jdk25.0.3+11-linux-amd64.tar.gz" | tar zx --strip-components=1 ;; esac

RUN mkdir -p /opt/jdk28 &&\
    cd /opt/jdk28 &&\
    case `uname -m` in aarch64) \
    curl -L "https://download.java.net/java/early_access/jdk28/3/GPL/openjdk-28-ea+3_linux-aarch64_bin.tar.gz" | tar zx --strip-components=1 ;; \
    *) curl -L "https://download.java.net/java/early_access/jdk28/3/GPL/openjdk-28-ea+3_linux-x64_bin.tar.gz" | tar zx --strip-components=1 ;; esac

WORKDIR /work

CMD /bin/bash
