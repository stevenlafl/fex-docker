# FEX Emulator Docker Image

A minimal, optimized Docker image for running x86 and x86_64 programs on ARM64 systems using [FEX-Emu](https://fex-emu.com/).

## What is FEX?

FEX allows you to run x86 applications on ARM64 Linux devices, similar to qemu-user and box64. It offers broad compatibility with both 32-bit and 64-bit x86 binaries, and it can be used alongside Wine/Proton to play Windows games.

### Key Features

- **API Forwarding**: Forwards API calls to host system libraries (OpenGL, Vulkan) to reduce emulation overhead
- **Code Cache**: Experimental code cache minimizes in-game stuttering
- **Per-App Configuration**: Tweak performance per application (e.g., skip costly memory model emulation)
- **FEXConfig GUI**: User-friendly interface to explore and change emulation settings
- **Broad Compatibility**: Supports both 32-bit and 64-bit x86 binaries

## What's Included

- **FEX-Emu**: x86/x86_64 emulator for ARM64 with binfmt support
- **FEX RootFS**: Ubuntu 24.04 x86_64 root filesystem (SquashFS, ~843MB)
- **Ubuntu 24.04 ARM64**: Minimal base image for ARM64 hosts

## Image Size

Optimized using multi-stage builds and minimal dependencies:

- **Content Size**: ~1.05GB
- **Disk Usage**: ~2.53GB

## Quick Start

### Using Docker Compose (Recommended)

```bash
docker-compose up -d
docker exec -it fex-emulator /bin/bash
```

### Using Pre-built Image

```bash
docker pull stevenlafl/fex:latest
docker run -it --rm stevenlafl/fex:latest
```

## Build from Source

```bash
docker build -t stevenlafl/fex:latest .
```

## Usage

### Interactive Shell

The container starts with FEXBash by default, providing an x86 emulated environment:

```bash
docker run -it --rm stevenlafl/fex:latest
```

### Running x86/x86_64 Binaries

```bash
# Inside FEXBash (default), binaries run automatically in emulated environment:
docker run -it --rm -v /path/to/x86/app:/app stevenlafl/fex:latest
cd /app && ./your-x86-binary

# To run a specific binary directly, use FEX:
docker run -it --rm -v /path/to/x86/app:/app stevenlafl/fex:latest FEX /app/your-x86-binary
```

## Optimization Details

This Dockerfile is optimized for minimal image size:

1. **Multi-stage build** - Build dependencies don't bloat final image
2. **--no-install-recommends** - Prevents unnecessary package suggestions
3. **Layer cleanup** - Aggressive removal of apt cache, temp files
4. **Auto-remove dependencies** - Purges build tools after use
5. **SquashFS RootFS** - 577MB smaller than EROFS format

## Technical Details

### FEX Executables

The image includes several FEX utilities:

- **FEX** - Main emulator executable for running x86/x86_64 programs
  ```bash
  FEX /path/to/x86-binary
  ```

- **FEXInterpreter** - Deprecated alias for FEX (backwards compatibility)

- **FEXConfig** - Qt-based GUI for configuring emulation settings

- **FEXBash** - Starts a bash instance running under emulation
  ```bash
  FEXBash
  ```
  Note: This is not a chroot! Don't use `sudo` inside this environment.

- **FEXMountDaemon** - Background mount daemon for SquashFS-based rootfs
  - Usually one instance runs at a time
  - Closes when FEX exits (with 10-second timeout window)
  - Automatically managed; manual intervention rarely needed

### FEX RootFS

The image uses the official FEX Ubuntu 24.04 x86_64 RootFS:
- **Type**: SquashFS (compressed filesystem)
- **Location**: `~/.fex-emu/RootFS/Ubuntu_24_04.sqsh`
- **Source**: https://rootfs.fex-emu.gg/
- **Purpose**: Provides x86_64 system libraries for emulated binaries

### Binfmt Support

The image includes `fex-emu-binfmt32` and `fex-emu-binfmt64` for transparent x86/x86_64 binary execution on ARM64 hosts.

## License

This Docker configuration is provided as-is. FEX-Emu and included components have their own licenses.

## Links

- [FEX-Emu Official Site](https://fex-emu.com/)
- [FEX-Emu GitHub](https://github.com/FEX-Emu/FEX)
- [FEX RootFS Repository](https://rootfs.fex-emu.gg/)
