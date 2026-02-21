# TODO: all of the git repos could be inputs.....
{
  description = "A Nix flake for VPinball";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    vpinball = {
      type = "github";
      owner = "vpinball";
      repo = "vpinball";
      flake = false;
    };

    #https://github.com/vpinball/vpinball/blob/master/platforms/config.sh
    libdmdutil = {
      type = "github";
      owner = "vpinball";
      repo = "libdmdutil";
      flake = false;
    };
    freeimage = {
      type = "github";
      owner = "toxieainc";
      repo = "freeimage";
      flake = false;
    };
    bgfx-cmake = {
      # We have to use this url path to get it to fetch submodules
      type = "git";
      url = "https://github.com/bkaradzic/bgfx.cmake?ref=v1.136.9135-511";
      submodules = true;
      #type = "github";
      #owner = "bkaradzic";
      #repo = "bgfx.cmake";
      #ref = "v1.136.9135-511";
      flake = false;
    };
    bgfx-patch = {
      type = "github";
      owner = "vbousquet";
      repo = "bgfx";
      flake = false;
    };
    pinmame = {
      type = "github";
      owner = "vbousquet";
      repo = "pinmame";
      flake = false;
    };
    libaltsound = {
      type = "github";
      owner = "vpinball";
      repo = "libaltsound";
      flake = false;
    };
    libdof = {
      type = "github";
      owner = "jsm174";
      repo = "libdof";
      flake = false;
    };
    sdl3 = {
      type = "github";
      owner = "libsdl-org";
      repo = "SDL";
      flake = false;
    };
    sdl3-image = {
      type = "github";
      owner = "libsdl-org";
      repo = "SDL_image";
      flake = false;
    };
    sdl3-ttf = {
      type = "github";
      owner = "libsdl-org";
      repo = "SDL_ttf";
      flake = false;
    };
    libzip = {
      type = "github";
      owner = "nih-at";
      repo = "libzip";
      flake = false;
    };
    ffmpeg = {
      type = "github";
      owner = "FFmpeg";
      repo = "FFmpeg";
      flake = false;
    };

    # https://github.com/vpinball/libdmdutil/blob/master/platforms/config.sh
    libusb = {
      type = "github";
      owner = "libusb";
      repo = "libusb";
      flake = false;
    };
    libzedmd = {
      type = "github";
      owner = "ppuc";
      repo = "libzedmd";
      flake = false;
    };
    libserum = {
      type = "github";
      owner = "ppuc";
      repo = "libserum_concentrate";
      flake = false;
    };
    libpupdmd = {
      type = "github";
      owner = "ppuc";
      repo = "libpupdmd";
      flake = false;
    };
    libvni = {
      type = "github";
      owner = "PPUC";
      repo = "libvni";
      flake = false;
    };

    # https://github.com/PPUC/libzedmd/blob/main/platforms/config.sh
    sockpp = {
      type = "github";
      owner = "fpagliughi";
      repo = "sockpp";
      flake = false;
    };
    cargs = {
      type = "github";
      owner = "likle";
      repo = "cargs";
      flake = false;
    };
    libframeutil = {
      type = "github";
      owner = "ppuc";
      repo = "libframeutil";
      flake = false;
    };
    libserialport = {
      type = "github";
      owner = "sigrokproject";
      repo = "libserialport";
      flake = false;
    };

    # https://github.com/jsm174/libdof/blob/master/platforms/config.sh
    libftdi = {
      type = "github";
      owner = "jsm174";
      repo = "libftdi";
      flake = false;
    };
    hidapi = {
      type = "github";
      owner = "libusb";
      repo = "hidapi";
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

      pkgsFor = forAllSystems (
        system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = [ self.overlays.default ]; # TODO: move individual packages out to package.nix files and use overlays
        }
      );
    in
    {

      # TODO: convert these from overlays into flake packages.
      overlays.default = final: prev: {
        bgfx = final.callPackage ./pkgs/bgfx {
          bgfx-cmake = inputs.bgfx-cmake;
          bgfx-patch = inputs.bgfx-patch;
        };
        cargs = final.callPackage ./pkgs/cargs { inherit inputs; };
        freeimage = final.callPackage ./pkgs/freeimage { inherit inputs; };
        libaltsound = final.callPackage ./pkgs/libaltsound { inherit inputs; };
        libdmdutil = final.callPackage ./pkgs/libdmdutil { inherit inputs; };
        libdof = final.callPackage ./pkgs/libdof { inherit inputs; };
        libframeutil = final.callPackage ./pkgs/libframeutil { inherit inputs; };
        libpupdmd = final.callPackage ./pkgs/libpupdmd { inherit inputs; };
        libserum = final.callPackage ./pkgs/libserum { inherit inputs; };
        libzedmd = final.callPackage ./pkgs/libzedmd { inherit inputs; };
        pinmame = final.callPackage ./pkgs/pinmame { inherit inputs; };
        #sdl3 = final.callPackage ./pkgs/sdl3 { inherit inputs; };
        #sdl3-ttf = final.callPackage ./pkgs/sdl3-ttf { inherit inputs; };
        #sdl3-image = final.callPackage ./pkgs/libdof { inherit inputs; };
        sockpp = final.callPackage ./pkgs/sockpp { inherit inputs; };
        libusb = final.callPackage ./pkgs/libusb { inherit inputs; };
        libvni = final.callPackage ./pkgs/libvni { inherit inputs; };
        libftdi = final.callPackage ./pkgs/libftdi { inherit inputs; };
        libserialport = final.callPackage ./pkgs/libserialport { inherit inputs; };
        hidapi = final.callPackage ./pkgs/hidapi { inherit inputs; };
      };

      packages = forAllSystems (
        system:
        let
          pkgs = pkgsFor.${system};
        in
        {

          vpinball = pkgs.callPackage ./pkgs/vpinball { inherit inputs; };

          default = self.packages.${system}.vpinball;

        }
      );

      devShells = forAllSystems (
        system:
        let
          pkgs = pkgsFor.${system};

          updateInputs = pkgs.mkShell {
            buildInputs = self.packages.${system}.vpinball.buildInputs;

            shellHook = ''
              nix develop .#updateDirectInputs
              nix develop .#updateChildInputs
              exit
            '';
          };

          # Updates inputs with SHA hashes from config.sh in the vpinball repo.
          updateDirectInputs = pkgs.mkShell {
            buildInputs = self.packages.${system}.vpinball.buildInputs;

            shellHook = ''
              if [ -f "${inputs.vpinball}/platforms/config.sh" ]; then
                source "${inputs.vpinball}/platforms/config.sh"

                echo "Updating SHA hashes from config.sh"

                echo "Updating sdl3: ''${SDL_SHA}"
                nix flake update sdl3 --override-input sdl3 github:libsdl-org/SDL/''${SDL_SHA}

                echo "Updating sdl3-ttf: ''${SDL_TTF_SHA}"
                nix flake update sdl3-ttf --override-input sdl3-ttf github:libsdl-org/SDL_ttf/''${SDL_TTF_SHA}

                echo "Updating sdl3-image: ''${SDL_IMAGE_SHA}"
                nix flake update sdl3-image --override-input sdl3-image github:libsdl-org/SDL_image/''${SDL_IMAGE_SHA}

                echo "Updating freeimage: ''${FREEIMAGE_SHA}"
                nix flake update freeimage --override-input freeimage github:toxieainc/freeimage/''${FREEIMAGE_SHA}

                echo "Updating libaltsound: ''${LIBALTSOUND_SHA}"
                nix flake update libaltsound --override-input libaltsound github:vpinball/libaltsound/''${LIBALTSOUND_SHA}

                echo "Updating bgfx-patch: ''${BGFX_PATCH_SHA}"
                nix flake update bgfx-patch --override-input bgfx-patch github:vbousquet/bgfx/''${BGFX_PATCH_SHA}

                echo "Updating pinmame: ''${PINMAME_SHA}"
                nix flake update pinmame --override-input pinmame github:vbousquet/pinmame/''${PINMAME_SHA}

                echo "Updating libdmdutil: ''${LIBDMDUTIL_SHA}"
                nix flake update libdmdutil --override-input libdmdutil github:vpinball/libdmdutil/''${LIBDMDUTIL_SHA}

                echo "Updating libdof: ''${LIBDOF_SHA}"
                nix flake update libdof --override-input libdof github:jsm174/libdof/''${LIBDOF_SHA}

                echo "Updating ffmpeg: ''${FFMPEG_SHA}"
                nix flake update ffmpeg --override-input ffmpeg github:FFmpeg/FFmpeg/''${FFMPEG_SHA}

                echo "Updating libzip: ''${LIBZIP_SHA}"
                nix flake update libzip --override-input libzip github:nih-at/libzip/''${LIBZIP_SHA}

                # TODO: fix, This throws errors
                #nix flake update bgfx-cmake --override-input bgfx-cmake 'git+https://github.com/bkaradzic/bgfx.cmake?ref=v1.129.8940-498'

                echo "✅ Updated the flake inputs from main config.sh"
              else
                echo "⚠️  Could not find config.sh in the 'vpinball' input. Please adjust the path in flake.nix."
              fi

              exit
            '';
          };

          # Updates inputs from SHA hashes defined in dependency repos.
          updateChildInputs = pkgs.mkShell {
            buildInputs = self.packages.${system}.vpinball.buildInputs;

            # This hook runs after the shell is built and ready.
            shellHook = ''
              # This hook updates the flake.lock hashes from the config.sh script in the main vpinball repo.
              echo "Updating SHA hashes from libdmdutil"
              if [ -f "${inputs.libdmdutil}/platforms/config.sh" ]; then
                source "${inputs.libdmdutil}/platforms/config.sh"

                # TODO: libusb conflict
                echo "Updating libusb: ''${LIBUSB_SHA}"
                nix flake update libusb --override-input libusb github:libusb/libusb/''${LIBUSB_SHA}

                echo "Updating libzedmd: ''${LIBZEDMD_SHA}"
                nix flake update libzedmd --override-input libzedmd github:PPUC/libzedmd/''${LIBZEDMD_SHA}
                echo "Updating libserum: ''${LIBSERUM_SHA}"
                nix flake update libserum --override-input libserum github:PPUC/libserum/''${LIBSERUM_SHA}
                echo "Updating libpupdmd: ''${LIBPUPDMD_SHA}"
                nix flake update libpupdmd --override-input libpupdmd github:PPUC/libpupdmd/''${LIBPUPDMD_SHA}
                echo "Updating libvni: ''${LIBVNI_SHA}"
                nix flake update libvni --override-input libvni github:PPUC/libvni/''${LIBVNI_SHA}
                OLD_LIBUSB_SHA="''${LIBUSB_SHA}"

                echo "✅ Updated the flake inputs from libdmdutil"
              else
                echo "⚠️  Could not find config.sh in the 'libdmdutil' input. Please adjust the path in flake.nix."
              fi

              echo "Updating SHA hashes from libdof"
              if [ -f "${inputs.libdof}/platforms/config.sh" ]; then
                source "${inputs.libdof}/platforms/config.sh"

                if [ "''${OLD_LIBUSB_SHA}" != "''${LIBUSB_SHA}" ]; then
                  echo "⚠️ Error: libusb hash mismatch" >&2
                  exit 1
                fi

                echo "Updating libserialport: ''${LIBSERIALPORT_SHA}"
                nix flake update libserialport --override-input libserialport github:sigrokproject/libserialport/''${LIBSERIALPORT_SHA}
                echo "Updating hidapi: ''${HIDAPI_SHA}"
                nix flake update hidapi --override-input hidapi github:libusb/hidapi/''${HIDAPI_SHA}
                echo "Updating libftdi: ''${LIBFTDI_SHA}"
                nix flake update libftdi --override-input libftdi github:jsm174/libftdi/''${LIBFTDI_SHA}
                OLD_LIBSERIALPORT_SHA="''${LIBSERIALPORT_SHA}"

                echo "✅ Updated the flake inputs from libdof"
              else
                echo "⚠️  Could not find config.sh in the 'libdof' input. Please adjust the path in flake.nix."
              fi

              echo "Updating SHA hashes from libzedmd"
              if [ -f "${inputs.libzedmd}/platforms/config.sh" ]; then
                source "${inputs.libzedmd}/platforms/config.sh"

                if [ "''${OLD_LIBSERIALPORT_SHA}" != "''${LIBSERIALPORT_SHA}" ]; then
                  echo "⚠️ Error: libserialport hash mismatch" >&2
                  exit 1
                fi

                echo "Updating cargs: ''${CARGS_SHA}"
                nix flake update cargs --override-input cargs github:likle/cargs/''${CARGS_SHA}
                echo "Updating libframeutil: ''${LIBFRAMEUTIL_SHA}"
                nix flake update libframeutil --override-input libframeutil github:ppuc/libframeutil/''${LIBFRAMEUTIL_SHA}
                echo "Updating sockpp: ''${SOCKPP_SHA}"
                nix flake update sockpp --override-input sockpp github:fpagliughi/sockpp/''${SOCKPP_SHA}

                echo "✅ Updated the flake inputs from libzedmd"
              else
                echo "⚠️  Could not find config.sh in the 'libzedmd' input. Please adjust the path in flake.nix."
              fi

              exit
            '';
          };
        in
        {
          #default = updateDirectInputs;

          inherit updateInputs;
          inherit updateDirectInputs;
          inherit updateChildInputs;
        }
      );
    };
}
