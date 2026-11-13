{
  description = "A Nix flake for VPinball";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    vpx-editor = {
      type = "github";
      owner = "jsm174";
      repo = "vpx-editor";
      flake = false;
    };

    vpinball = {
      type = "github";
      owner = "vpinball";
      repo = "vpinball";
      flake = false;
    };

    bgfx-cmake = {
      type = "tarball";
      url = "https://github.com/bkaradzic/bgfx.cmake/releases/download/v1.167.9605-606/bgfx.cmake.v1.167.9605-606.tar.gz";
      flake = false;
    };

    vpinfe = {
      type = "github";
      owner = "superhac";
      repo = "vpinfe";
      flake = false;
      ref = "v2.6.6";
    };

    vpxtool = {
      type = "github";
      owner = "francisdb";
      repo = "vpxtool";
      ref = "v0.26.0";
      flake = false;
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      ...
    }:
    let
      supportedSystems = [ "x86_64-linux" ];

      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      # Pure Nix extraction and git fetch of upstream dependency SHAs
      upstreamSources = import ./upstream-sources.nix {
        vpinball = inputs.vpinball;
        bgfx-cmake = inputs.bgfx-cmake;
      };

      # vpinfe release tag pinned by scripts/update_vpinfe.sh (from flake.lock).
      # Null when the input is not pinned to a tag.
      vpinfeRelease =
        let
          lock = builtins.fromJSON (builtins.readFile (self.sourceInfo.outPath + "/flake.lock"));
        in
          lock.nodes.vpinfe.original.ref or null;

      # Merged inputs accessible by derivations in pkgs/
      allInputs = inputs // upstreamSources // { inherit vpinfeRelease; };

      # SHA-pinned custom packages for vpinball and its dependencies, built
      # as a scope on top of a given nixpkgs set (`base`).
      #
      # Deliberately NOT applied as a global overlay: packages in pkgs/
      # reference these explicitly via their `vpinPkgs` argument, so
      # unrelated nixpkgs packages (chromium, etc.) keep their standard
      # builds and stay substitutable from the binary cache.
      #
      # The scope's callPackage resolves arguments from `base // self`, so
      # inside pkgs/ the `pkgs` argument is still plain nixpkgs while
      # `vpinPkgs` provides the custom builds (custom names shadow nixpkgs
      # only within the scope). Cross-dependencies between custom packages
      # (e.g. opusfile -> libogg/libopus) resolve through
      # the scope lazily, so attribute order here does not matter.
      vpinPkgs =
        base: buildType:
        base.lib.makeScope base.newScope (
          self:
          let
            callPackage = self.callPackage;
          in
          {
            # Expose the scope to packages that take a `vpinPkgs` argument;
            # the scope's callPackage resolves it automatically from `self`.
            vpinPkgs = self;

            bgfx = callPackage ./pkgs/bgfx {
              bgfx-cmake = allInputs.bgfx-cmake;
              bgfx-patch = allInputs.bgfx-patch;
              inherit buildType;
            };
            bgfx-shaderc = callPackage ./pkgs/bgfx-shaderc {
              bgfx-cmake = allInputs.bgfx-cmake;
              bgfx-patch = allInputs.bgfx-patch;
            };
            openxr = callPackage ./pkgs/openxr { inputs = allInputs; inherit buildType; };
            # Static, SHA-pinned copies of libs that also exist in nixpkgs.
            # Same names as the nixpkgs versions, but the shadowing is
            # confined to this scope, so unrelated packages are unaffected.
            # vpinball stages them into its third-party/ tree.
            zlib = callPackage ./pkgs/zlib { inputs = allInputs; inherit buildType; };
            libogg = callPackage ./pkgs/libogg { inputs = allInputs; inherit buildType; };
            libopus = callPackage ./pkgs/libopus { inputs = allInputs; inherit buildType; };
            opusfile = callPackage ./pkgs/opusfile { inputs = allInputs; inherit buildType; };
            libmysofa = callPackage ./pkgs/libmysofa { inputs = allInputs; inherit buildType; };
            libspatialaudio = callPackage ./pkgs/libspatialaudio { inputs = allInputs; inherit buildType; };
            pinmame-data = callPackage ./pkgs/pinmame-data { inputs = allInputs; };
            cargs = callPackage ./pkgs/cargs { inputs = allInputs; inherit buildType; };
            freeimage = callPackage ./pkgs/freeimage { inputs = allInputs; inherit buildType; };
            libaltsound = callPackage ./pkgs/libaltsound { inputs = allInputs; inherit buildType; };
            libdmdutil = callPackage ./pkgs/libdmdutil { inputs = allInputs; inherit buildType; };
            libwinevbs = callPackage ./pkgs/libwinevbs { inputs = allInputs; inherit buildType; };
            libdof = callPackage ./pkgs/libdof { inputs = allInputs; inherit buildType; };
            libframeutil = callPackage ./pkgs/libframeutil { inputs = allInputs; };
            libpupdmd = callPackage ./pkgs/libpupdmd { inputs = allInputs; inherit buildType; };
            libserum = callPackage ./pkgs/libserum { inputs = allInputs; inherit buildType; };
            libzedmd = callPackage ./pkgs/libzedmd { inputs = allInputs; inherit buildType; };
            pinmame = callPackage ./pkgs/pinmame { inputs = allInputs; inherit buildType; };
            sockpp = callPackage ./pkgs/sockpp { inputs = allInputs; inherit buildType; };
            libusb = callPackage ./pkgs/libusb { inputs = allInputs; };
            libvni = callPackage ./pkgs/libvni { inputs = allInputs; inherit buildType; };
            libftdi = callPackage ./pkgs/libftdi { inputs = allInputs; inherit buildType; };
            libserialport = callPackage ./pkgs/libserialport { inputs = allInputs; };
            hidapi = callPackage ./pkgs/hidapi { inputs = allInputs; inherit buildType; };

            # SDL has a lot of custom build options in upstream nixpkgs for audio and video stuff.
            # If necessary to force support for wayland you can add a .override to these to enable waylandSupport
            sdl3 = callPackage ./pkgs/sdl3 { inputs = allInputs; inherit buildType; };
            sdl3-ttf = callPackage ./pkgs/sdl3-ttf { inputs = allInputs; inherit buildType; };
            sdl3-image = callPackage ./pkgs/sdl3-image { inputs = allInputs; inherit buildType; };
          }
        );

      # Plain nixpkgs: the custom vpinball packages are NOT applied as an
      # overlay here, so unrelated packages (chromium, ...) keep their
      # standard, binary-cache-friendly builds.
      pkgsFor = forAllSystems (
        system:
        import nixpkgs {
          inherit system;
          # Required for pinmame: legacy MAME files in the tree carry the
          # original non-commercial MAME license, so nixpkgs classifies the
          # package as unfreeRedistributable. Everything else in this flake
          # is free software.
          config.allowUnfree = true;
        }
      );
    in
    {
      legacyPackages = forAllSystems (
        system: {
          sources = upstreamSources;
          inherit (upstreamSources) configs;
        }
      );

      packages = forAllSystems (
        system:
        let
          pkgs = pkgsFor.${system};

          # vpinball plus its custom dependency tree, all built with the
          # given build type (Release or Debug) so internal shared libraries
          # (libpinmame.so, libdof.so, ...) carry matching debug symbols.
          makeVPinball =
            buildType:
            pkgs.callPackage ./pkgs/vpinball {
              inputs = allInputs;
              inherit buildType;
              vpinPkgs = vpinPkgs pkgs buildType;
            };
        in
        {
          vpinball = makeVPinball "Release";
          vpinball-debug = makeVPinball "Debug";

          vpinfe = pkgs.callPackage ./pkgs/vpinfe { inputs = allInputs; };
          vpxtool = pkgs.callPackage ./pkgs/vpxtool { inputs = allInputs; };
          vpx-editor = pkgs.callPackage ./pkgs/vpx-editor { inputs = allInputs; };

          default = self.packages.${system}.vpinball;
        }
      );

      devShells = forAllSystems (
        system:
        let
          pkgs = pkgsFor.${system};
        in
        {
          # Default shell provides a proper dev environment for working on vpinball
          default = pkgs.mkShell {
            inputsFrom = [ self.packages.${system}.vpinball ];
            packages = with pkgs; [
              git
              cmake
              ninja
              pkg-config
              gdb
            ];
          };
        }
      );
    };
}
