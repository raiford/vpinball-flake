# Pure Nix parser for upstream build configurations.
# Extracts commit SHAs declared across:
#   1. vpinball/platforms/config.sh
#   2. libdmdutil/platforms/config.sh
#   3. libdof/platforms/config.sh
#   4. libzedmd/platforms/config.sh
# and fetches the corresponding sources via builtins.fetchGit.

{ vpinball, bgfx-cmake }:
let
  # Parse a shell config file into an attribute set of KEY=VALUE strings.
  # Only matches variable assignments of the form *_SHA=... and *_VERSION=...
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

  # 1. Parse top-level vpinball config
  vpinballConfig = parseConfig "${vpinball}/platforms/config.sh";

  # 2. Fetch and parse direct dependency configs
  libdmdutilSrc = builtins.fetchGit {
    url = "https://github.com/vpinball/libdmdutil.git";
    rev = vpinballConfig.LIBDMDUTIL_SHA;
  };
  libdmdutilConfig = parseConfig "${libdmdutilSrc}/platforms/config.sh";

  libdofSrc = builtins.fetchGit {
    url = "https://github.com/jsm174/libdof.git";
    rev = vpinballConfig.LIBDOF_SHA;
  };
  libdofConfig = parseConfig "${libdofSrc}/platforms/config.sh";

  # 3. Fetch and parse transitive dependency configs
  libzedmdSrc = builtins.fetchGit {
    url = "https://github.com/PPUC/libzedmd.git";
    rev = libdmdutilConfig.LIBZEDMD_SHA;
  };
  libzedmdConfig = parseConfig "${libzedmdSrc}/platforms/config.sh";

  # SHA mismatch consistency checks
  _checkLibusb =
    if libdmdutilConfig.LIBUSB_SHA != libdofConfig.LIBUSB_SHA then
      builtins.trace "warning: libusb SHA mismatch between libdmdutil (${libdmdutilConfig.LIBUSB_SHA}) and libdof (${libdofConfig.LIBUSB_SHA}), using libdmdutil" null
    else null;

  _checkSerialport =
    if libdofConfig.LIBSERIALPORT_SHA != libzedmdConfig.LIBSERIALPORT_SHA then
      throw "libserialport SHA mismatch between libdof (${libdofConfig.LIBSERIALPORT_SHA}) and libzedmd (${libzedmdConfig.LIBSERIALPORT_SHA})"
    else null;
in
builtins.seq _checkLibusb (builtins.seq _checkSerialport {
  # Direct dependencies declared in vpinball/platforms/config.sh
  sdl3 = builtins.fetchGit {
    url = "https://github.com/libsdl-org/SDL.git";
    rev = vpinballConfig.SDL_SHA;
  };

  sdl3-image = builtins.fetchGit {
    url = "https://github.com/libsdl-org/SDL_image.git";
    rev = vpinballConfig.SDL_IMAGE_SHA;
    submodules = true;
  };

  sdl3-ttf = builtins.fetchGit {
    url = "https://github.com/libsdl-org/SDL_ttf.git";
    rev = vpinballConfig.SDL_TTF_SHA;
    submodules = true;
  };

  freeimage = builtins.fetchGit {
    url = "https://github.com/toxieainc/freeimage.git";
    rev = vpinballConfig.FREEIMAGE_SHA;
  };

  libaltsound = builtins.fetchGit {
    url = "https://github.com/vpinball/libaltsound.git";
    rev = vpinballConfig.LIBALTSOUND_SHA;
  };

  bgfx-patch = builtins.fetchGit {
    url = "https://github.com/vbousquet/bgfx.git";
    rev = vpinballConfig.BGFX_PATCH_SHA;
  };

  inherit bgfx-cmake;
  bgfxCmakeVersion = vpinballConfig.BGFX_CMAKE_VERSION;

  pinmame = builtins.fetchGit {
    url = "https://github.com/vbousquet/pinmame.git";
    rev = vpinballConfig.PINMAME_SHA;
  };

  libdmdutil = libdmdutilSrc;

  libwinevbs = builtins.fetchGit {
    url = "https://github.com/vpinball/libwinevbs.git";
    rev = vpinballConfig.LIBWINEVBS_SHA;
  };

  libdof = libdofSrc;

  libzip = builtins.fetchGit {
    url = "https://github.com/nih-at/libzip.git";
    rev = vpinballConfig.LIBZIP_SHA;
  };

  # Child dependencies declared in libdmdutil/platforms/config.sh
  libusb = builtins.fetchGit {
    url = "https://github.com/libusb/libusb.git";
    rev = libdmdutilConfig.LIBUSB_SHA;
  };

  libzedmd = libzedmdSrc;

  libserum = builtins.fetchGit {
    url = "https://github.com/PPUC/libserum.git";
    rev = libdmdutilConfig.LIBSERUM_SHA;
  };

  libpupdmd = builtins.fetchGit {
    url = "https://github.com/PPUC/libpupdmd.git";
    rev = libdmdutilConfig.LIBPUPDMD_SHA;
  };

  libvni = builtins.fetchGit {
    url = "https://github.com/PPUC/libvni.git";
    rev = libdmdutilConfig.LIBVNI_SHA;
  };

  # Child dependencies declared in libdof/platforms/config.sh
  libserialport = builtins.fetchGit {
    url = "https://github.com/sigrokproject/libserialport.git";
    rev = libdofConfig.LIBSERIALPORT_SHA;
  };

  hidapi = builtins.fetchGit {
    url = "https://github.com/libusb/hidapi.git";
    rev = libdofConfig.HIDAPI_SHA;
  };

  libftdi = builtins.fetchGit {
    url = "https://github.com/jsm174/libftdi.git";
    rev = libdofConfig.LIBFTDI_SHA;
  };

  # Child dependencies declared in libzedmd/platforms/config.sh
  cargs = builtins.fetchGit {
    url = "https://github.com/likle/cargs.git";
    rev = libzedmdConfig.CARGS_SHA;
  };

  libframeutil = builtins.fetchGit {
    url = "https://github.com/ppuc/libframeutil.git";
    rev = libzedmdConfig.LIBFRAMEUTIL_SHA;
  };

  sockpp = builtins.fetchGit {
    url = "https://github.com/fpagliughi/sockpp.git";
    rev = libzedmdConfig.SOCKPP_SHA;
  };

  # Note: FFMPEG_SHA is declared upstream in vpinball/platforms/config.sh
  # but provided by nixpkgs ffmpeg_7 rather than fetched as a source.
  ffmpegSha = vpinballConfig.FFMPEG_SHA or null;

  # Upstream configuration variables for auditing
  configs = {
    vpinball = vpinballConfig;
    libdmdutil = libdmdutilConfig;
    libdof = libdofConfig;
    libzedmd = libzedmdConfig;
  };
})
