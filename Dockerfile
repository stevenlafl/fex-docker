# Multi-stage build to minimize final image size
FROM ubuntu:24.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive

# Install only build-time dependencies with --no-install-recommends
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    jq \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Download FEX rootfs dynamically using jq
RUN mkdir -p /root/.fex-emu/RootFS \
    && ROOTFS_URL=$(curl -s https://rootfs.fex-emu.gg/RootFS_links.json | \
    jq -r '.v1 | to_entries[] | select(.value.DistroMatch == "ubuntu" and .value.DistroVersion == "24.04" and .value.Type == "squashfs") | .value.URL') \
    && echo "Downloading RootFS from: $ROOTFS_URL" \
    && curl -L -o /root/.fex-emu/RootFS/Ubuntu_24_04.sqsh "$ROOTFS_URL" \
    && echo '{"Config":{"RootFS":"Ubuntu_24_04.sqsh"}}' > /root/.fex-emu/Config.json

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
    && userdel -r ubuntu \
    && useradd -m -s /bin/bash fex \
    && install -d -m 0775 -o root -g fex /opt/.fex-emu \
    && ln -s /opt/.fex-emu /home/fex/.fex-emu

# Copy from builder stage
COPY --chmod=775 --chown=root:fex --from=builder /root/.fex-emu /opt/.fex-emu

ENV PATH="/root/.local/bin:${PATH}"

# ----------------
# CPU Options
# ----------------

# Controls multiblock code compilation; may cause long JIT compilation times and stutter
#ENV FEX_MULTIBLOCK=true

# Maximum number of instructions to store in a block
#ENV FEX_MAXINST=5000

# Enable the code caching subsystem
#ENV FEX_ENABLECODECACHINGWIP=false

# Controls CPU features in the JIT (enable/disable feature flags)
#ENV FEX_HOSTFEATURES=off

# Scales the cycle counter on systems that have low frequencies
#ENV FEX_SMALLTSCSCALE=true

# Override CPU feature flags for manual testing
#ENV FEX_CPUFEATUREREGISTERS=

# ----------------
# Emulation Options
# ----------------

# Which Root filesystem prefix to use; can be a path or named RootFS
#ENV FEX_ROOTFS=/opt/.fex-emu/RootFS/Ubuntu_24_04.sqsh

# Folder for host-side thunking libraries
#ENV FEX_THUNKHOSTLIBS=/usr/lib/aarch64-linux-gnu/fex-emu/HostThunks

# Folder for guest-side thunking libraries
#ENV FEX_THUNKGUESTLIBS=/usr/share/fex-emu/GuestThunks

# Path or named Thunk configuration JSON file
#ENV FEX_THUNKCONFIG=

# Adds environment variables to the emulated environment
#ENV FEX_ENV=

# Adds environment variables to the host environment
#ENV FEX_HOSTENV=

# Additional CLI arguments to the application
#ENV FEX_ADDITIONALARGUMENTS=

# Disable FEXCore's JIT L2 cache lookup (less memory, more stutter possible)
#ENV FEX_DISABLEL2CACHE=false

# Enables dynamically sized JIT L1 cache to save memory
#ENV FEX_DYNAMICL1CACHE=false

# Threshold (lookups/sec) to increase L1 cache size
#ENV FEX_DYNAMICL1CACHEINCREASECOUNTHEURISTIC=250

# Threshold (lookups/sec) to decrease L1 cache size
#ENV FEX_DYNAMICL1CACHEDECREASECOUNTHEURISTIC=50

# ----------------
# Debug Options
# ----------------

# Enable single stepping
#ENV FEX_SINGLESTEP=false

# Enable GDB remote server
#ENV FEX_GDBSERVER=false

# Dump IR [no, stdout, stderr, server, <folder>]
#ENV FEX_DUMPIR=no

# When to dump IR [off, beforeopt, afteropt, beforepass, afterpass]
#ENV FEX_PASSMANAGERDUMPIR=off

# Print GPR registers at program end
#ENV FEX_DUMPGPRS=false

# Disable optimization passes for debugging
#ENV FEX_O0=false

# Lump all JIT symbols as 'FEXJIT' for profiling
#ENV FEX_GLOBALJITNAMING=false

# Group JIT symbols by library name
#ENV FEX_LIBRARYJITNAMING=false

# Name each JIT block individually (profiling aid)
#ENV FEX_BLOCKJITNAMING=false

# Integrate with GDB via JIT interface
#ENV FEX_GDBSYMBOLS=false

# Preload libSegFault.so for crash debugging
#ENV FEX_INJECTLIBSEGFAULT=false

# VIXL disassembler mode [off, dispatcher, blocks, stats]
#ENV FEX_DISASSEMBLE=off

# Override SVE width (debugging only)
#ENV FEX_FORCESVEWIDTH=0

# Disable telemetry collection
#ENV FEX_DISABLETELEMETRY=false

# ----------------
# Logging Options
# ----------------

# Disable logging completely
#ENV FEX_SILENTLOG=true

# Logging destination [stdout, stderr, server, <filename>]
#ENV FEX_OUTPUTLOG=server

# Redirect FEX telemetry output directory
#ENV FEX_TELEMETRYDIRECTORY=

# Enable low-overhead runtime profile stats (requires MangoHud)
#ENV FEX_PROFILESTATS=false

# Enable GPUVIS profiler backend
#ENV FEX_ENABLEGPUVISPROFILING=false

# ----------------
# Hacks Options
# ----------------

# Code modification checks [none, mtrack(default), full]
#ENV FEX_SMCCHECKS=mtrack

# Enable TSO IR operations (required for multithreading)
#ENV FEX_TSOENABLED=true

# Vector load/store atomicity under TSO
#ENV FEX_VECTORTSOENABLED=false

# Atomic memcpy/memset under TSO
#ENV FEX_MEMCPYSETTSOENABLED=false

# Half-barrier atomics for unaligned load/store under TSO
#ENV FEX_HALFBARRIERTSOENABLED=true

# Strict lock for split-atomic handling across cacheline
#ENV FEX_STRICTINPROCESSSPLITLOCKS=false

# Backpatch unaligned atomic ops to reduce context switches
#ENV FEX_KERNELUNALIGNEDATOMICBACKPATCHING=true

# Use PE volatile metadata for TSO handling when available
#ENV FEX_VOLATILEMETADATA=true

# Use 64-bit x87 precision (faster, less accurate)
#ENV FEX_X87REDUCEDPRECISION=false

# Force process stall at startup (debugging)
#ENV FEX_STALLPROCESS=false

# Hide the hypervisor CPUID bit
#ENV FEX_HIDEHYPERVISORBIT=false

# Sleep duration in seconds before process startup
#ENV FEX_STARTUPSLEEP=0

# Only apply startup sleep to this process name
#ENV FEX_STARTUPSLEEPPROCNAME=

# Use Mono-specific SMC behavior and smaller JIT blocks
#ENV FEX_MONOHACKS=true

# ----------------
# Misc Options
# ----------------

# Override FEXServer socket path (for chroots)
#ENV FEX_SERVERSOCKETPATH=

# Disable inline syscalls to support seccomp
#ENV FEX_NEEDSSECCOMP=false

# Extended volatile metadata config string (WoW64/arm64ec)
#ENV FEX_EXTENDEDVOLATILEMETADATA=

# ----------------
# Additional Environment Variables (always available)
# ----------------

# Override where FEX looks for config files
#ENV FEX_APP_CONFIG_LOCATION=

# Override only the application config file location
#ENV FEX_APP_CONFIG=

# Override data file storage directory (includes caches)
#ENV FEX_APP_DATA_LOCATION=

# Make FEX run in portable mode; ignore system-wide locations
#ENV FEX_PORTABLE=

USER fex

WORKDIR /home/fex

CMD ["/usr/bin/FEXBash"]
