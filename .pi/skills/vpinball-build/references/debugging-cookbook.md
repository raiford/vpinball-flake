# VPinball Flake Debugging Cookbook

This cookbook lists common failure modes, compilation and linking errors, drift signatures, and runtime issues encountered when maintaining or modifying `vpinball-flake`.

---

## 1. Upstream Drift & Configuration Errors

### 1.1 Drift detected by `check-external.sh`

**Error / Warning**:
```
=== check-external.sh ===
upstream declares 32 SHA/VERSION vars
flake.nix handles 24 SHA/VERSION vars

DRIFT: upstream vars not wired into this flake:
  - LIBMYSOFA_SHA
  - LIBOGG_SHA
  ...
```

**Cause**:
Upstream updated `platforms/config.sh` and added new external dependencies (or new machine data like `PINMAME_MEMMAPS_SHA`), but `upstream-sources.nix` or `flake.nix` does not reference those variables yet.

**Fix**:
1. Inspect upstream `platforms/linux-x64/external.sh` to see:
   - What URL upstream fetches the dependency from.
   - What CMake/configure flags are passed.
   - What headers and libraries are copied into `third-party/`.
2. In `upstream-sources.nix`:
   - Add the fetch line using `fetchGithub` or `fetchGitSubmodules`:
     ```nix
     libmysofa = fetchGithub "hoene" "libmysofa" vpinballConfig.LIBMYSOFA_SHA;
     ```
3. If the dependency is a compiled library:
   - Create `pkgs/<new-dep>/default.nix`.
   - Wire it into `customPackages` in `flake.nix`.
   - Add it to `pkgs/vpinball/default.nix` under `buildInputs`.
4. If it's data (like `pinmame-data` memmaps/gamedefs):
   - Fetch the source in `upstream-sources.nix`.
   - In `pkgs/vpinball/default.nix`, copy or link the directories into `third-party/memmaps` and `third-party/gamedefs` during `preConfigure` if required by plugins.

---

### 1.2 Transitive SHA Mismatch (`_checkSerialport` / `_checkLibusb`)

**Error**:
```
error: libserialport SHA mismatch between libdof (...) and libzedmd (...)
```

**Cause**:
`upstream-sources.nix` detected that two different upstream dependencies declare conflicting commit hashes for the same library in their respective `platforms/config.sh`.

**Fix**:
1. Check both commits in upstream repositories to see if one is ahead of the other.
2. In `upstream-sources.nix`, review the assertion:
   - If one repository is the canonical upstream authority (e.g. `libdof` vs `libzedmd`), decide which SHA to adopt or loosen the check to a `builtins.trace` warning (similar to `_checkLibusb`).
   - If both require exact compatibility, patch or override the upstream source to match the unified SHA.

---

### 1.3 `fetchTree` / `fetchGit` Revision Not Found

**Error**:
```
fatal: reference is not a tree: <sha>
or
error: cannot find Git revision '<sha>' in <repo>
```

**Cause**:
The commit SHA pinned by upstream is not on the default branch (`main` or `master`), but on a topic branch or detached tag. Standard `fetchGit` without `allRefs = true` only queries branch tips.

**Fix**:
- **For GitHub repos**: Always use `fetchGithub` (`builtins.fetchTree { type = "github"; ... }`). GitHub's archive tarball endpoint resolves any commit regardless of branch.
- **For Git repos with submodules**: Always use `fetchGitSubmodules` with `allRefs=1`:
  ```nix
  fetchGitSubmodules = url: rev:
    builtins.fetchTree "git+${url}?submodules=1&allRefs=1&rev=${rev}";
  ```

---

## 2. Build-Time Compilation & Configuration Errors

### 2.1 The `$src` Read-Only Store Trap in `preConfigure`

**Error**:
```
cp: cannot create regular file '/nix/store/...-vpinball/third-party/tools/linux-x64/shaderc': Read-only file system
```

**Cause**:
In `pkgs/vpinball/default.nix`, the script wrote to `$src/third-party/...`.
In Nix stdenv, `$src` points to the immutable Nix store path of the fetched source.
During build phases, the builder's current working directory (`$PWD`) is an unpacked, writable copy of the source tree.

**Fix**:
Use a relative path, **never** `$src`:
```nix
preConfigure = ''
  mkdir -p third-party/tools/linux-x64
  cp ${pkgs.bgfx-shaderc}/bin/shaderc third-party/tools/linux-x64/
'';
```

---

### 2.2 Missing `shaderc` Host Tool

**Error**:
```
CMake Error at make/CMakeLists_shaders.txt:34 (message):
  shaderc not found under third-party/tools/. Run BUILD_TYPE=<config>
  ./platforms/<platform>-<arch>/external.sh first.
```

**Cause**:
Upstream's `make/CMakeLists_shaders.txt` hardcodes looking for `shaderc` in `${CMAKE_SOURCE_DIR}/third-party/tools/${PLATFORM}-${ARCH}` with `NO_DEFAULT_PATH`.

**Fix**:
1. Ensure `pkgs.bgfx-shaderc` is in `nativeBuildInputs` of `pkgs/vpinball`.
2. Stage it in `preConfigure`:
   ```nix
   mkdir -p third-party/tools/linux-x64
   cp ${pkgs.bgfx-shaderc}/bin/shaderc third-party/tools/linux-x64/
   ```

---

### 2.3 `POST_BUILD_COPY_EXT_LIBS` Copy Failures

**Error**:
```
cp: cannot stat '.../third-party/runtime-libs/linux-x64/libSDL3.so': No such file or directory
```

**Cause**:
Upstream CMake has `POST_BUILD_COPY_EXT_LIBS=ON` by default. It expects `external.sh` to have filled `third-party/runtime-libs/`. Since Nix provides libraries through `buildInputs` and Nix store paths, the `third-party/runtime-libs/` directory is empty.

**Fix**:
Always pass `-DPOST_BUILD_COPY_EXT_LIBS=OFF` in `cmakeFlags` for `vpinball`, `libdmdutil`, `libdof`, and other derivations:
```nix
cmakeFlags = [
  "-DPOST_BUILD_COPY_EXT_LIBS=OFF"
];
```

---

### 2.4 License Failure on `pinmame`

**Error**:
```
error: Package 'pinmame' in /.../pkgs/pinmame/default.nix:12 has an unfree license ('unfreeRedistributable')...
```

**Cause**:
`pinmame` incorporates legacy MAME files with the non-commercial MAME license. Nixpkgs marks it as `unfreeRedistributable`.

**Fix**:
Ensure any Nix evaluation or nixpkgs instantiation sets `config.allowUnfree = true`.
In `flake.nix`, `pkgsFor` sets:
```nix
import nixpkgs {
  inherit system;
  config.allowUnfree = true;
  overlays = [ self.overlays.default ];
}
```
If using `nix build` with ad-hoc expressions, pass `--impure` or set `NIXPKGS_ALLOW_UNFREE=1`.

---

### 2.5 `cmake_minimum_required` Incompatibility (e.g. `libftdi`)

**Error**:
```
CMake Error at CMakeLists.txt:1 (cmake_minimum_required):
  Compatibility with CMake < 3.10 has been removed from a recent version of CMake.
```

**Cause**:
Old upstream libraries (like `libftdi`) have `cmake_minimum_required(VERSION 2.6)`. Modern CMake in nixpkgs rejects versions older than 3.5 or 3.10.

**Fix**:
Patch the file in `preConfigure`:
```nix
preConfigure = ''
  sed -i.bak 's/cmake_minimum_required([^)]*)/cmake_minimum_required(VERSION 3.10)/' CMakeLists.txt
'';
```

---

### 2.6 Format String Hardening Errors

**Error**:
```
error: format not a string literal and no format arguments [-Werror=format-security]
```

**Cause**:
Nixpkgs enables strict compiler hardening flags by default (`-Werror=format-security`). Legacy C code in Wine, VBScript, or MAME triggers this error.

**Fix**:
In the derivation:
```nix
hardeningDisable = [ "format" ];
```
Or pass `-DCMAKE_C_FLAGS=-Wno-format-security`.

---

### 2.7 Header Not Found for Sub-Dependency

**Error**:
```
fatal error: DMDUtil/DMDUtil.h: No such file or directory
or
fatal error: ZeDMD.h: No such file or directory
```

**Cause**:
Upstream CMake files add `${CMAKE_SOURCE_DIR}/third-party/include` to the include path.
In Nix, the compiler wrapper turns packages in `buildInputs` into `-isystem <pkg>/include`.
If the package installs its header as `$out/include/foo.h` but the caller does `#include <DMDUtil/foo.h>`, the directory structure inside `$out/include` must match the include directive.

**Fix**:
Check `installPhase` in the dependency package:
- For `libdmdutil`: headers must be at `$out/include/DMDUtil/DMDUtil.h`.
- For `libwinevbs`: headers must mirror `$out/include/libwinevbs/`, `$out/include/wine/`, `$out/include/atl/`.
- For `libframeutil`: header-only copy of `include/*` to `$out/include/`.

---

## 3. Runtime & Post-Build Issues

### 3.1 Segfault on Launch: `~/.config/user-dirs.dirs`

**Symptom**:
`VPinballX` crashes immediately on startup with a segfault before rendering any window.

**Cause**:
Visual Pinball checks standard XDG user directories (e.g. `XDG_DOCUMENTS_DIR`). If `~/.config/user-dirs.dirs` is missing or incomplete, unhandled null pointers can cause an immediate crash.

**Fix**:
Run `xdg-user-dirs-update` in the user environment to generate standard XDG user directories.

---

### 3.2 Wayland vs X11 Display Issues

**Symptom**:
Black window, crash in `libSDL3.so` under Wayland, or failure to open display.

**Cause**:
`sdl3` supports both X11 and Wayland backends. If one backend lacks proper runtime support or drivers, SDL may fail during initialization.

**Diagnostic / Workaround**:
Force the video driver at runtime:
```sh
SDL_VIDEODRIVER=x11 result/bin/VPinballX
# or
SDL_VIDEODRIVER=wayland result/bin/VPinballX
```
In `pkgs/sdl3/default.nix`, both `-DSDL_X11=ON` and `-DSDL_WAYLAND=ON` are enabled explicitly so missing build-time dependencies fail at build time rather than runtime.
