---
name: vpinball-build
description: >
  Expert guide for developing, adjusting, and debugging the vpinball-flake Nix build.
  Use when adding new upstream dependencies or plugins, bumping upstream vpinball or library
  commits, debugging compilation, linking, shader, or runtime errors, checking drift with
  upstream build scripts (platforms/config.sh and external.sh), or understanding the
  pure Nix hash extraction architecture in upstream-sources.nix and flake.nix.
---

# VPinball Nix Build Expert

This skill guides you through developing, modifying, and debugging `vpinball-flake` (a native Nix build of Visual Pinball / VPinballX on Linux).

Read `references/architecture.md` for full architectural mapping between upstream scripts and pure Nix.
Read `references/debugging-cookbook.md` for specific error signatures, root causes, and diagnostic fixes.

---

## 1. Quick Reference: Core Architecture

```
flake.nix (inputs: vpinball, bgfx-cmake, vpx-editor, vpinfe, vpxtool, nixpkgs)
    │
    ▼
upstream-sources.nix
    ├── 1. Parses vpinball/platforms/config.sh (*_SHA, *_VERSION)
    ├── 2. Fetches libdmdutil & libdof via builtins.fetchTree (GitHub archive API)
    ├── 3. Parses their platforms/config.sh to fetch child deps (libzedmd, libserum, etc.)
    ├── 4. Parses libzedmd/platforms/config.sh for cargs, sockpp, libframeutil
    └── 5. Verifies SHA consistency across transitive dependencies
    │
    ▼
flake.nix (allInputs = inputs // upstreamSources)
    ├── overlays.default (injects customPackages from pkgs/*)
    ├── packages.vpinball (Release) & packages.vpinball-debug (Debug)
    └── devShells.default
```

### Key Differences from Upstream

| Concept | Upstream Behavior | `vpinball-flake` Behavior |
|---|---|---|
| **Dependency Download** | `platforms/linux-x64/external.sh` downloads tarballs with `curl` during build. | `upstream-sources.nix` parses SHAs in pure Nix and fetches via `builtins.fetchTree`. Sandbox has NO network. |
| **Dependency Staging** | Copies compiled `.so`/`.a` and headers into `third-party/` in the source tree. | Each dependency is an individual Nix derivation in `pkgs/`. Nix compiler wrapper injects `-isystem` and `-L` flags via `buildInputs`. |
| **Host Tools** | `shaderc` built into `third-party/tools/linux-x64/`. | Built by `pkgs/bgfx-shaderc` and copied into `third-party/tools/linux-x64/` during `preConfigure` in `pkgs/vpinball`. |
| **Copying Ext Libs** | `POST_BUILD_COPY_EXT_LIBS=ON` copies `.so` next to binary. | `POST_BUILD_COPY_EXT_LIBS=OFF` in CMake flags. Nix handles rpath and library paths automatically. |
| **License Requirement** | Legacy MAME code in `pinmame`. | `config.allowUnfree = true` required in nixpkgs evaluation. |

---

## 2. Standard Workflows

### Workflow 1: Bumping Upstream VPinball

1. **Update the flake input**:
   ```bash
   nix flake update vpinball
   # Or to pin a specific upstream commit:
   # nix flake update vpinball --override-input vpinball github:/vpinball/vpinball/<commit-sha>
   ```
2. **Check for upstream drift**:
   ```bash
   bash ./scripts/check-external.sh
   ```
   If drift is detected, upstream has added new `*_SHA` or `*_VERSION` variables. Follow **Workflow 2**.
3. **Dry-run build**:
   ```bash
   nix build --dry-run .
   ```
4. **Build and test**:
   ```bash
   nix build --show-trace .
   ./result/bin/VPinballX
   ```

---

### Workflow 2: Adding a New Upstream Dependency

When `check-external.sh` reports a missing variable (e.g. `LIBFOO_SHA`):

1. **Inspect upstream usage**:
   - Check upstream `platforms/linux-x64/external.sh` for download URL, CMake options, and what headers/libs are copied into `third-party/`.
   - Check `make/CMakeLists_app.txt` or `make/CMakeLists_plugins.txt` to see which target links against it (`target_link_libraries`).

2. **Wire into `upstream-sources.nix`**:
   - For standard GitHub repos without submodules:
     ```nix
     libfoo = fetchGithub "owner" "repo" vpinballConfig.LIBFOO_SHA;
     ```
   - For repos requiring submodules (e.g. SDL auxiliary libs):
     ```nix
     libfoo = fetchGitSubmodules "https://github.com/owner/repo" vpinballConfig.LIBFOO_SHA;
     ```

3. **Create the derivation in `pkgs/<name>/default.nix`**:
   ```nix
   {
     lib,
     stdenv,
     pkgs,
     inputs,
     buildType ? "Release",
   }:
   stdenv.mkDerivation {
     name = "libfoo";
     src = inputs.libfoo;

     nativeBuildInputs = with pkgs; [ cmake pkg-config ];
     buildInputs = with pkgs; [ /* dependencies */ ];

     cmakeFlags = [
       "-DPLATFORM=linux"
       "-DARCH=x64"
       "-DBUILD_STATIC=OFF"
       "-DPOST_BUILD_COPY_EXT_LIBS=OFF"
       "-DCMAKE_BUILD_TYPE=${buildType}"
     ];

     meta = with lib; {
       description = "...";
       homepage = "...";
       license = licenses.mit;
       platforms = platforms.linux;
     };
   }
   ```

4. **Register in `flake.nix`**:
   Add to `customPackages final prev`:
   ```nix
   libfoo = final.callPackage ./pkgs/libfoo { inputs = allInputs; };
   ```

5. **Add to `pkgs/vpinball/default.nix`**:
   Add `libfoo` to `buildInputs`.

6. **Verify drift check clears**:
   ```bash
   bash ./scripts/check-external.sh
   ```

---

### Workflow 3: Adjusting Build Options or Adding Debug Builds

- **Release Build**: `nix build .#vpinball` (or `nix build .`)
- **Debug Build**: `nix build .#vpinball-debug`
  - In `flake.nix`, `makeVPinball "Debug"` uses `pkgs.extend` to automatically invoke `.override { buildType = "Debug"; }` on every custom package that takes `buildType`.
  - When writing or modifying any package under `pkgs/`, always accept `buildType ? "Release"` and pass `-DCMAKE_BUILD_TYPE=${buildType}`.

---

## 3. Critical Rules & Traps for AI Agents

1. **NEVER write to `$src` during build phases**:
   - In `preConfigure` or `postUnpack`, `$src` is a read-only store path (`/nix/store/...`).
   - The current working directory (`$PWD`) is the unpacked, writable workspace.
   - **Incorrect**: `cp ${pkgs.bgfx-shaderc}/bin/shaderc $src/third-party/tools/...`
   - **Correct**: `mkdir -p third-party/tools/linux-x64 && cp ${pkgs.bgfx-shaderc}/bin/shaderc third-party/tools/linux-x64/`

2. **Always disable `POST_BUILD_COPY_EXT_LIBS`**:
   - Upstream CMake scripts have custom commands that run `cp` on `.so` files from `third-party/runtime-libs/`.
   - In Nix, these files do not exist there. Always pass `-DPOST_BUILD_COPY_EXT_LIBS=OFF`.

3. **GitHub Tarballs vs Git Protocol**:
   - Commits pinned in `platforms/config.sh` are often not on branch heads.
   - Never use plain `fetchGit` without `allRefs = true`.
   - Use `builtins.fetchTree { type = "github"; owner = ...; repo = ...; rev = ...; }` for GitHub repos (uses tarball API, immune to Git branch restrictions).

4. **Always allow unfree licenses**:
   - `pinmame` contains legacy MAME code. Any `import nixpkgs` expression must set `config.allowUnfree = true`.

5. **C/C++ Hardening Security Flags**:
   - If a package fails with `-Werror=format-security` (common in Wine, VBScript, or MAME legacy code), add `hardeningDisable = [ "format" ];` to the derivation.

6. **Do NOT commit changes unless instructed**:
   - Inspect with `git status` and `git diff`. Test builds with `nix build --dry-run .` and `nix build --show-trace .`.
