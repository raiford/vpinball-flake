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

      # Merged inputs accessible by derivations in pkgs/
      allInputs = inputs // upstreamSources;

      customPackages = final: prev: {
        bgfx = final.callPackage ./pkgs/bgfx {
          bgfx-cmake = allInputs.bgfx-cmake;
          bgfx-patch = allInputs.bgfx-patch;
        };
        cargs = final.callPackage ./pkgs/cargs { inputs = allInputs; };
        freeimage = final.callPackage ./pkgs/freeimage { inputs = allInputs; };
        libaltsound = final.callPackage ./pkgs/libaltsound { inputs = allInputs; };
        libdmdutil = final.callPackage ./pkgs/libdmdutil { inputs = allInputs; };
        libwinevbs = final.callPackage ./pkgs/libwinevbs { inputs = allInputs; };
        libdof = final.callPackage ./pkgs/libdof { inputs = allInputs; };
        libframeutil = final.callPackage ./pkgs/libframeutil { inputs = allInputs; };
        libpupdmd = final.callPackage ./pkgs/libpupdmd { inputs = allInputs; };
        libserum = final.callPackage ./pkgs/libserum { inputs = allInputs; };
        libzedmd = final.callPackage ./pkgs/libzedmd { inputs = allInputs; };
        pinmame = final.callPackage ./pkgs/pinmame { inputs = allInputs; };
        sockpp = final.callPackage ./pkgs/sockpp { inputs = allInputs; };
        libusb = final.callPackage ./pkgs/libusb { inputs = allInputs; };
        libvni = final.callPackage ./pkgs/libvni { inputs = allInputs; };
        libftdi = final.callPackage ./pkgs/libftdi { inputs = allInputs; };
        libserialport = final.callPackage ./pkgs/libserialport { inputs = allInputs; };
        hidapi = final.callPackage ./pkgs/hidapi { inputs = allInputs; };

        # SDL has a lot of custom build options in upstream nixpkgs for audio and video stuff.
        # If necessary to force support for wayland you can add a .override to these to enable waylandSupport
        sdl3 = prev.sdl3.overrideAttrs (old: {
          src = allInputs.sdl3;
          version = "";
        });
        sdl3-ttf = prev.sdl3-ttf.overrideAttrs (old: {
          src = allInputs.sdl3-ttf;
          version = "";
        });
        sdl3-image = prev.sdl3-image.overrideAttrs (old: {
          src = allInputs.sdl3-image;
          version = "";
        });
      };

      pkgsFor = forAllSystems (
        system:
        import nixpkgs {
          inherit system;
          # Required for pinmame: legacy MAME files in the tree carry the
          # original non-commercial MAME license, so nixpkgs classifies the
          # package as unfreeRedistributable. Everything else in this flake
          # is free software.
          config.allowUnfree = true;
          overlays = [ self.overlays.default ];
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

      overlays.default = final: prev: customPackages final prev;

      packages = forAllSystems (
        system:
        let
          pkgs = pkgsFor.${system};
          customNames = builtins.attrNames (customPackages pkgs pkgs);

          makeVPinball =
            buildType:
            let
              relevantPkgs =
                if buildType == "Release" then
                  pkgs
                else
                  pkgs.extend (
                    final: prev:
                    pkgs.lib.genAttrs customNames (
                      name:
                        if prev.${name} ? override && (prev.${name}.override.__functionArgs.buildType or false)
                        then prev.${name}.override { inherit buildType; }
                        else prev.${name}
                    )
                  );
            in
            relevantPkgs.callPackage ./pkgs/vpinball { inputs = allInputs; inherit buildType; };
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

          # Backwards-compatibility shells (informative since SHAs are now parsed dynamically)
          updateInputs = pkgs.mkShell {
            shellHook = ''
              echo "✅ Pattern 3 is active: upstream dependency SHAs are parsed automatically in pure Nix from platforms/config.sh."
              echo "To bump upstream vpinball, simply run: nix flake update vpinball"
              exit 0
            '';
          };
          updateDirectInputs = pkgs.mkShell {
            shellHook = ''
              echo "✅ Direct inputs are parsed automatically in pure Nix from vpinball/platforms/config.sh."
              exit 0
            '';
          };
          updateChildInputs = pkgs.mkShell {
            shellHook = ''
              echo "✅ Child inputs are parsed automatically in pure Nix from dependency platforms/config.sh files."
              exit 0
            '';
          };
        }
      );
    };
}
