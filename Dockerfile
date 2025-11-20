# Multi-stage build to minimize final image size
FROM ubuntu:24.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive

# Install only build-time dependencies with --no-install-recommends
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    gnupg \
    jq \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Download FEX rootfs (SquashFS is 577MB smaller than EROFS)
RUN mkdir -p /root/.fex-emu/RootFS && \
    curl -L -o /root/.fex-emu/RootFS/Ubuntu_24_04.sqsh \
    "https://rootfs.fex-emu.gg/Ubuntu_24_04/2025-03-04/Ubuntu_24_04.sqsh" && \
    echo '{"Config":{"RootFS":"Ubuntu_24_04.sqsh"}}' > /root/.fex-emu/Config.json

# Final runtime stage
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Install only runtime dependencies with --no-install-recommends
RUN apt-get update && apt-get install -y --no-install-recommends \
    software-properties-common \
    gnupg \
    fuse3 \
    && add-apt-repository -y ppa:fex-emu/fex \
    && apt-get update && apt-get install -y --no-install-recommends \
    fex-emu-armv8.0 \
    fex-emu-binfmt32 \
    fex-emu-binfmt64 || true \
    && apt-get purge -y --auto-remove software-properties-common gnupg || true \
    && apt-get clean || true \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/cache/apt/archives/* \
    && update-binfmts --enable \
    && useradd -m -s /bin/bash fex \
    && install -d -m 0775 -o root -g fex /opt/.fex-emu \
    && ln -s /opt/.fex-emu /home/fex/.fex-emu

# Copy from builder stage
COPY --chmod=775 --chown=root:fex --from=builder /root/.fex-emu /opt/.fex-emu

ENV PATH="/root/.local/bin:${PATH}"

USER fex

WORKDIR /home/fex

CMD ["/usr/bin/FEXBash"]
