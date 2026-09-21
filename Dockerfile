FROM ubuntu:24.04

RUN apt-get update && apt-get install -y \
    bash \
    curl \
    jq \
    xz-utils \
    tar \
    dpkg-dev \
    fakeroot \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY build.sh .
RUN chmod +x build.sh

CMD ["./build.sh"]
