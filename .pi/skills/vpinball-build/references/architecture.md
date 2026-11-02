# VPinball Flake Architecture & Upstream Mapping

This document details the build architecture of `vpinball-flake`, how upstream Visual Pinball builds its dependency tree, and how this Nix flake translates upstream shell scripts into pure Nix derivations.

---

## 1. Upstream Build Architecture

Upstream Visual Pinball (`vpinball/vpinball`) targets multiple platforms (Linux x64/aarch64, Windows MSVC/MinGW, macOS, iOS, Android, WASM). On Linux x64, it does **not** rely on distribution package managers or CMake `FetchContent`. Instead, it uses custom shell scripts in `platforms/`:

### 1.1 The Upstream Script Hierarchy

1. **`platforms/config.sh`**:
   Declares exact Git commit SHAs and release versions for every dependency needed by Visual Pinball:
   ```bash
   SDL_SHA=829a65d769d935c4852f8159e964312c0957260a
   SDL_IMAGE_SHA=f661fa1ad24ab1b81e43662532f9a6a9fcf67ea6
   SDL_TTF_SHA=a1ce3670aec736ecbf0936c43f2f0cc53aa61e5b
   FREEIMAGE_SHA=b1613452a0c3849d43ac877b154cf51ff9e078d3
   BGFX_CMAKE_VERSION=1.167.9605-606
   BGFX_PATCH_SHA=bdca10b074bf77cc40f5f811d08ab6331e3a6d81
   PINMAME_SHA=9dfcbd0f2539d96f8739f1c78250716135fa4b74
   LIBDMDUTIL_SHA=6b8f711a5346cf2e70562872ebc1a57b210906df
   LIBDOF_SHA=5c54ef784ddc31738a9b2a422380f170bd63121b
   ...
   ```

2. **`platforms/linux-x64/external.sh`**:
   Executed before CMake. It:
   - Downloads source tarballs into `external/linux-x64/${BUILD_TYPE}/`.
   - Compiles each library using CMake or Autotools.
   - For `bgfx`: builds both the shared runtime library (`libbgfx.so`) and the host tool `shaderc` (built with `-DCMAKE_BUILD_TYPE=Release`).
   - Copies headers and built binaries into the `third-party/` directory of the vpinball source tree:
     - `third-party/include/`: headers (`SDL3/`, `bgfx/`, `bimg/`, `bx/`, `FreeImage.h`, `pinmame/`, `libwinevbs/`, etc.).
     - `third-party/runtime-libs/linux-x64/`: shared libraries (`libSDL3.so`, `libbgfx.so`, `libpinmame.so`, etc.).
     - `third-party/build-libs/linux-x64/`: static libraries (`libbimg_encode.a`, `libz.a`, `libmysofa.a`, etc.).
     - `third-party/tools/linux-x64/`: build-time host tools (`shaderc`).
     - `third-party/memmaps/` & `third-party/gamedefs/`: PinMAME table/machine definitions.

3. **Transitive Dependency Scripts**:
   The direct dependencies themselves maintain their own `platforms/config.sh` and `platforms/linux/x64/external.sh`:
   - **`libdmdutil`**:
     - Declares: `LIBZEDMD_SHA`, `LIBSERUM_SHA`, `LIBPUPDMD_SHA`, `LIBVNI_SHA`, `LIBUSB_SHA`.
     - Builds and stages ZeDMD, Serum, PUP DMD, VNI, and LibUSB.
   - **`libdof`**:
     - Declares: `LIBSERIALPORT_SHA`, `HIDAPI_SHA`, `LIBFTDI_SHA`, `LIBUSB_SHA`.
     - Builds and stages serial port, FTDI, HID, and USB libraries.
   - **`libzedmd`**:
     - Declares: `CARGS_SHA`, `LIBSERIALPORT_SHA`, `LIBFRAMEUTIL_SHA`, `SOCKPP_SHA`.
     - Builds and stages CLI args, frame utilities, socket wrapper, and serial port.

### 1.2 Upstream CMake Build Configuration

When upstream CMake runs (`CMakeLists.txt` and `make/CMakeLists_*.txt`):
- It targets `PLATFORM=linux`, `ARCH=x64`, `RENDERER=BGFX` (or `GL`).
- `make/CMakeLists_shaders.txt` looks for the host tool `shaderc`:
  ```cmake
  find_program(VPX_SHADERC
     NAMES shaderc shaderc.exe
     PATHS "${CMAKE_SOURCE_DIR}/third-party/tools/${PLATFORM}-${ARCH}"
     NO_DEFAULT_PATH)
  ```
- `make/CMakeLists_app.txt`:
  - Links against libraries found in `${CMAKE_SOURCE_DIR}/third-party/runtime-libs/linux-x64` and `build-libs/linux-x64`.
  - Searches headers in `${CMAKE_SOURCE_DIR}/third-party/include`.
  - Has `POST_BUILD_COPY_EXT_LIBS` (default ON) which attempts to copy `.so` files from `third-party/runtime-libs/` to the binary output directory.
- `make/CMakeLists_plugins.txt`:
  - Builds individual plugins (`pinmame`, `dof`, `dmdutil`, `altsound`, `serum`, `pup`, `vni`, etc.) as shared modules staged in `${TARGET_DIR}/plugins/<name>/`.

---

## 2. Nix Flake Architecture (Pure Nix "Pattern 3")

In Nix, derivations run in an isolated sandbox with **no network access**. We cannot let `external.sh` download dependencies during the build.

### 2.1 The "Pattern 3" Revolution

Earlier iterations of `vpinball-flake` maintained 20+ separate flake inputs in `flake.nix` and `flake.lock`. Whenever upstream bumped a dependency, the lockfile had to be manually re-pinned.

**Pattern 3** solves this by evaluating upstream configs directly in **pure Nix**:
- `flake.nix` only has flake inputs for root projects (`vpinball`, `vpx-editor`, `vpinfe`, `vpxtool`, `bgfx-cmake`, and `nixpkgs`).
- `upstream-sources.nix` parses the upstream shell scripts at evaluation time and fetches the exact Git revisions declared upstream.

```
flake.lock ─────────► inputs.vpinball
                             │
                             ▼
                  upstream-sources.nix
                  (pure Nix parseConfig)
                             │
       ┌─────────────────────┼─────────────────────┐
       ▼                     ▼                     ▼
vpinballConfig        libdmdutilConfig        libdofConfig
(platforms/config.sh) (platforms/config.sh)   (platforms/config.sh)
       │                     │                     │
       ▼                     ▼                     ▼
  direct deps          transitive deps        transitive deps
  (SDL, bgfx,          (libserum, libpup,     (libserialport,
   pinmame, ...)        libzedmd, ...)         hidapi, libftdi)
                             │
                             ▼
                      libzedmdConfig
                      (platforms/config.sh)
                             │
                             ▼
                        child deps
                        (cargs, sockpp, libframeutil)
```

### 2.2 Hash Extraction Mechanism (`upstream-sources.nix`)

1. **`parseConfig`**:
   Reads a shell script into a string using `builtins.readFile`, splits on newlines, matches assignments of the form `KEY_SHA=value` or `KEY_VERSION=value` using `builtins.match`, and converts them to a Nix attribute set:
   ```nix
   parseConfig = file:
     let
       text = builtins.readFile file;
       lines = builtins.filter builtins.isString (builtins.split "\n" text);
       isShaOrVersion = l: builtins.match "^[[:space:]]*[A-Za-z0-9_]+(_SHA|_VERSION)=.*" l != null;
       assignLines = builtins.filter isShaOrVersion lines;
       parseLine = l:
         let
           m = builtins.match "^[[:space:]]*([A-Za-z0-9_]+)=[\"']?([^\"'[:space:]]+)[\"']?.*$" l;
         in {
           name = builtins.head m;
           value = builtins.elemAt m 1;
         };
     in builtins.listToAttrs (map parseLine assignLines);
   ```

2. **Fetching Git Commits (`fetchGithub` vs `fetchGitSubmodules`)**:
   - **`fetchGithub owner repo rev`**:
     Uses `builtins.fetchTree { type = "github"; inherit owner repo rev; }`.
     *Why*: Standard Git protocol shallow fetches fail when upstream pins a commit that is not the head of a branch (e.g. an unmerged branch commit or detached tag). GitHub's archive tarball API bypasses this limitation.
   - **`fetchGitSubmodules url rev`**:
     Uses `builtins.fetchTree "git+${url}?submodules=1&allRefs=1&rev=${rev}"`.
     *Why*: Used for `sdl3-image` and `sdl3-ttf` which vendor formats (libpng, libjpeg, libwebp, harfbuzz, etc.) as Git submodules. The `allRefs=1` parameter tells Nix/Lix to search all Git refs to locate the commit.

3. **Consistency Verification**:
   When multiple sub-dependencies pin the same shared library, `upstream-sources.nix` verifies consistency:
   - `_checkSerialport`: Throws a hard error if `libdof` and `libzedmd` request different `LIBSERIALPORT_SHA` commits.
   - `_checkLibusb`: Emits a trace warning if `libdmdutil` and `libdof` disagree on `LIBUSB_SHA`.

---

## 3. Derivations and Package Architecture (`pkgs/`)

All custom packages live under `pkgs/` and are injected into nixpkgs via `overlays.default` in `flake.nix`.

### 3.1 Overlay Injection & Parameterization

In `flake.nix`:
```nix
customPackages = final: prev: {
  bgfx = final.callPackage ./pkgs/bgfx { ... };
  bgfx-shaderc = final.callPackage ./pkgs/bgfx-shaderc { ... };
  pinmame = final.callPackage ./pkgs/pinmame { inputs = allInputs; };
  libdmdutil = final.callPackage ./pkgs/libdmdutil { inputs = allInputs; };
  ...
};
```
Every package receives `inputs = allInputs;` (where `allInputs = inputs // upstreamSources;`).

### 3.2 Debug vs Release Propagation

`flake.nix` exports both `packages.vpinball` (Release) and `packages.vpinball-debug` (Debug):
- For Debug builds, `pkgs.extend` overrides every package in `customPackages` with `{ buildType = "Debug"; }` if the package's `.override` takes `buildType`.
- This ensures all internal C++ shared libraries (`libpinmame.so`, `libdof.so`, `libdmdutil.so`, etc.) are built with debug symbols and matching ABI flags.

### 3.3 Key Package Quirks and Solutions

| Package | Upstream Source | Quirks & Nix Strategy |
|---|---|---|
| **`vpinball`** | `vpinball/vpinball` | Requires `bgfx-shaderc` in `third-party/tools/linux-x64/` before CMake configure. Disables `POST_BUILD_COPY_EXT_LIBS=OFF`. Sets `-DCMAKE_CXX_FLAGS=-mssse3`. Hardening disable `format`. |
| **`bgfx`** | `bkaradzic/bgfx.cmake` + `vbousquet/bgfx` | Combines tarball release of `bgfx.cmake` with patched `bgfx` repo by replacing `bgfx.cmake/bgfx` in `postUnpack`. Builds shared library `libbgfx.so` and `libbimg_encode.a`. |
| **`bgfx-shaderc`** | Same as `bgfx` | Builds ONLY the host tool `shaderc` (`--target shaderc`) with `-DCMAKE_BUILD_TYPE=Release`. Output binary goes to `$out/bin/shaderc`. |
| **`pinmame`** | `vbousquet/pinmame` | Copies `cmake/libpinmame/CMakeLists.txt` to root in `postUnpack`. License is `unfreeRedistributable` (legacy MAME code); requires `config.allowUnfree = true` in nixpkgs. |
| **`libwinevbs`** | `vpinball/libwinevbs` | Wine/ReactOS VBScript engine. Requires `bison` in `nativeBuildInputs`. Exports headers into `$out/include/libwinevbs`, `wine/`, `atl/`, `atlmfc/`. Requires `-Wno-format-security`. |
| **`libftdi`** | `jsm174/libftdi` | Requires patching `cmake_minimum_required(VERSION 3.10)` via `sed` in `preConfigure`. Explicitly passes `-DLIBUSB_INCLUDE_DIR` and `-DLIBUSB_LIBRARIES`. |
| **`libserialport`** | `sigrokproject/libserialport` | Autotools build (`./autogen.sh`). Requires `autoconf`, `automake`, `libtool`. |
| **`libusb`** | `libusb/libusb` | Autotools build (`./autogen.sh`). Requires `systemd` (`libudev`). |
| **`hidapi`** | `libusb/hidapi` | CMake build. Requires `systemd` (`libudev`). Flags: `-DHIDAPI_WITH_LIBUSB=OFF`. |
| **`libframeutil`**| `ppuc/libframeutil` | Header-only library. `dontBuild = true`. Installs headers to `$out/include`. |
| **`sdl3`** | `libsdl-org/SDL` | Pinned explicitly with `-DSDL_X11=ON -DSDL_WAYLAND=ON` to ensure loud build failures rather than silent missing-driver runtime bugs. |
| **`sdl3-image`** | `libsdl-org/SDL_image` | Git fetch with recursive submodules (`allRefs=1`). `-DSDLIMAGE_VENDORED=ON`. |
| **`sdl3-ttf`** | `libsdl-org/SDL_ttf` | Git fetch with recursive submodules (`allRefs=1`). `-DSDLTTF_VENDORED=ON`. |
| **`ffmpeg`** | Upstream pins SHA | Handled via nixpkgs `ffmpeg_7` rather than compiling from source, matching ABI. |
