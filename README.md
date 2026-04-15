# vpinball-flake

## Overview

A nix flake for building and running [Visual Pinball](https://github.com/vpinball/vpinball). This is essentially a port of the visual pinball stand-alone build scripts to the nix build system.

## Update flow

Upstream vpinball's `external.sh` fetches ~25 third-party libraries at build time. This flake decomposes each into its own `pkgs/<name>/default.nix` derivation, with the source provided as a flake input. Hashes live in `flake.lock`.

Because `vpinball` itself, `libdmdutil`, `libdof`, and `libzedmd` each carry their own `platforms/config.sh` files that pin *their* third-party deps, the update process is a **cascade**: bump `vpinball` → re-read its `config.sh` → update direct deps → re-read each direct dep's own `config.sh` → update the transitive deps they pull in.

Two dev shells implement the cascade:

- `nix develop .#updateDirectInputs` — reads `${inputs.vpinball}/platforms/config.sh` and updates the direct deps (SDL, bgfx, pinmame, libdmdutil, libdof, etc.).
- `nix develop .#updateChildInputs` — reads the `config.sh` files inside `libdmdutil`, `libdof`, and `libzedmd`, and updates the transitive deps (libusb, libzedmd, libserum, libserialport, hidapi, libftdi, cargs, sockpp, libframeutil, etc.).
- `nix develop .#updateInputs` — runs both in sequence.

### Manual update

```sh
just update
# equivalent to:
#   nix flake update vpinball
#   nix develop '.#updateInputs'
```

Then `nix build .#vpinball` to verify the result compiles, and commit `flake.lock`.

To pin to a specific upstream commit instead of latest master:

```sh
just update-commit <sha>
```

### Automated update (scheduled GitHub Actions)

`.github/workflows/update-vpinball.yml` runs the same cascade weekly (Monday ~06:00 Pacific) and on `workflow_dispatch`. Each run:

1. Bumps the `vpinball` input to upstream master.
2. Runs `nix develop .#updateInputs`, capturing the output to `cascade.log`.
3. Greps the log for `hash mismatch` / `CONFLICT` warnings (transitive dep disagreements — see below).
4. Attempts `nix build .#vpinball -L`.
5. Opens or updates a PR at `chore/update-vpinball` via `peter-evans/create-pull-request`, attaching the cascade log as a workflow artifact.
6. Marks the job red if any of the three gates failed.

**The workflow never auto-merges.** A human reviews the PR, smoke-tests a known-good table locally, then merges.

## Update runbook

### Green PR (all gates passed)

1. Check out the PR branch locally: `git fetch origin chore/update-vpinball && git checkout chore/update-vpinball`.
2. `nix build .#vpinball` locally — should be a cache hit via cachix or a quick incremental build if anything has changed in the derivation since CI ran.
3. Smoke-test a known-good table. Launching a table through your frontend of choice is the meaningful check — the build passing in CI only means the code compiles, not that runtime libs behave.
4. Merge the PR once the smoke test passes.

### Draft PR (cascade or build failed)

The workflow opens the PR as a draft and marks the job red when any of these fail:

- **Cascade exited non-zero.** Usually caused by a `libserialport` or `libusb` hash mismatch — see the conflict reconciliation section below.
- **`hash mismatch` / `CONFLICT` appeared in `cascade.log` as a warning.** Same as above, but the cascade continued past it (libusb's check is a warning, libserialport's is fatal).
- **`nix build .#vpinball -L` failed.** Could be (a) upstream vpinball broke, (b) the cascade picked a combination of dep versions that don't compile together, (c) a new `pkgs/<name>/default.nix` is needed for a newly-added upstream dep.

Triage steps:

1. Download the `cascade-log` artifact from the workflow run and read it. It shows exactly which SHAs the cascade tried to set.
2. If the failure is a build error for a known-good source combination, bisect by pinning `vpinball` to the previous good SHA (`just update-commit <prev-sha>`) and re-running — that isolates "upstream broke" from "our packaging broke."
3. If the failure is a transitive dep conflict, follow the reconciliation section below.
4. If the failure is a newly-added upstream dep that the flake doesn't know about yet, add an input + `pkgs/<name>/default.nix` for it (this is manual packaging work).

### Transitive dep conflict reconciliation (libusb, libserialport)

`libdmdutil/platforms/config.sh` and `libdof/platforms/config.sh` both pin `LIBUSB_SHA`. `libdof/platforms/config.sh` and `libzedmd/platforms/config.sh` both pin `LIBSERIALPORT_SHA`. When upstream dependencies update at different cadences, these sibling pins can disagree — the cascade dev shell detects this and prints `⚠️ Error: libusb hash mismatch` or similar.

The libusb mismatch is currently a warning (the `exit 1` is commented out in `updateChildInputs`); the libserialport one is fatal. Either way, the human fix is the same:

1. Pick a winning SHA. Usually the newer of the two, unless the newer one regresses behavior.
2. Edit the losing `platforms/config.sh` locally — or, preferably, override the flake input directly:

   ```sh
   nix flake update libusb --override-input libusb github:libusb/libusb/<winning-sha>
   ```

3. Re-run `nix build .#vpinball -L` to confirm both sides still compile against the chosen SHA.
4. Commit the adjusted `flake.lock` to the same `chore/update-vpinball` branch and push. The workflow will re-run on the PR and (hopefully) clear.

Long-term fix is an upstream conversation with vpinball/libdmdutil/libdof to reconcile their pinning strategies, but that's out of scope for this flake.

## License

GPL-3.0. See [LICENSE](LICENSE). 
