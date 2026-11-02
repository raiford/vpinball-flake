# vpinball-flake

A Nix flake that builds [Visual Pinball](https://github.com/vpinball/vpinball) (VPinballX) for Linux from source. It is a native Nix port of the upstream `platforms/` build scripts (`config.sh` + `external.sh`), which normally clone and compile the dependency tree by hand.

## What it builds

| Package              | Description                                                                                 |
| -------------------- | ------------------------------------------------------------------------------------------- |
| `vpinball` (default) | VPinballX engine, Release build                                                             |
| `vpinball-debug`     | VPinballX engine, Debug build (all custom deps rebuilt as Debug)                            |
| `vpinfe`             | [VPinFE](https://github.com/superhac/vpinfe) front-end (Python/pywebview)                   |
| `vpxtool`            | [vpxtool](https://github.com/francisdb/vpxtool) — CLI for manipulating `.vpx` tables (Rust) |
| `vpx-editor`         | [vpx-editor](https://github.com/jsm174/vpx-editor) — Electron-based table editor            |

## How it works

- **Pinned sources.** Every dependency is a flake input pinned to the exact SHA that upstream's `config.sh` files declare, so the Nix build matches what vpinball is tested against. `pkgs/` contains a derivation for each dependency (bgfx, pinmame, libdof, libdmdutil, libzedmd, SDL3 + SDL_image/SDL_ttf with vendored format libs, etc.).
- **Overlay.** `overlays.default` injects the custom packages into nixpkgs; the flake also sets `allowUnfree` for pinmame (legacy MAME files carry the non-commercial MAME license).
- **Drift check.** `scripts/check-external.sh` compares the `*_SHA`/`*_VERSION` variables the upstream Linux build scripts reference against what the flake's update hooks handle, flagging new upstream dependencies that haven't been wired in yet.

## Usage

Requires [just](https://github.com/casey/just) (or run the commands directly):

```sh
just build          # nix build .  →  result/VPinballX
just update         # bump vpinball to upstream master, then re-sync all input SHAs
just update-commit <sha>   # pin vpinball to a specific commit, then re-sync
```

Run the game with `result/bin/VPinballX` (or `nix run .#vpinball`).

## Notes

- Only `x86_64-linux` is supported (matching the upstream `linux-x64` platform scripts).
- ffmpeg comes from nixpkgs (`ffmpeg`) rather than an upstream-pinned source.

## License

[GPL-3.0](LICENSE)
