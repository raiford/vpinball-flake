# Pure Nix parser for upstream build configurations.
# Extracts commit SHAs declared across:
#   1. vpinball/platforms/config.sh
#   2. libdmdutil/platforms/config.sh
#   3. libdof/platforms/config.sh
#   4. libzedmd/platforms/config.sh
# and fetches sources via builtins.fetchTree.

{ vpinball, bgfx-cmake }:
let
  # Use builtins.fetchTree with GitHub archive API for GitHub repos.
  # This avoids git protocol branch limitations (e.g. commits not on refs/heads/master).
  fetchGithub = owner: repo: rev:
    builtins.fetchTree {
      type = "github";
      inherit owner repo rev;
    };

  # Git fetch with submodules and allRefs enabled using the flakeref URL format.
  # This ensures Lix and Nix fetch across all branches to find non-main commits.
  fetchGitSubmodules = url: rev:
    builtins.fetchTree "git+${url}?submodules=1&allRefs=1&rev=${rev}";

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
  libdmdutilSrc = fetchGithub "vpinball" "libdmdutil" vpinballConfig.LIBDMDUTIL_SHA;
  libdmdutilConfig = parseConfig "${libdmdutilSrc}/platforms/config.sh";

  libdofSrc = fetchGithub "jsm174" "libdof" vpinballConfig.LIBDOF_SHA;
  libdofConfig = parseConfig "${libdofSrc}/platforms/config.sh";

  # 3. Fetch and parse transitive dependency configs
  libzedmdSrc = fetchGithub "PPUC" "libzedmd" libdmdutilConfig.LIBZEDMD_SHA;
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
  sdl3 = fetchGithub "libsdl-org" "SDL" vpinballConfig.SDL_SHA;

  sdl3-image = fetchGitSubmodules "https://github.com/libsdl-org/SDL_image" vpinballConfig.SDL_IMAGE_SHA;

  sdl3-ttf = fetchGitSubmodules "https://github.com/libsdl-org/SDL_ttf" vpinballConfig.SDL_TTF_SHA;

  freeimage = fetchGithub "toxieainc" "freeimage" vpinballConfig.FREEIMAGE_SHA;

  libaltsound = fetchGithub "vpinball" "libaltsound" vpinballConfig.LIBALTSOUND_SHA;

  bgfx-patch = fetchGithub "vbousquet" "bgfx" vpinballConfig.BGFX_PATCH_SHA;

  inherit bgfx-cmake;
  bgfxCmakeVersion = vpinballConfig.BGFX_CMAKE_VERSION;

  pinmame = fetchGithub "vbousquet" "pinmame" vpinballConfig.PINMAME_SHA;

  libdmdutil = libdmdutilSrc;

  libwinevbs = fetchGithub "vpinball" "libwinevbs" vpinballConfig.LIBWINEVBS_SHA;

  libdof = libdofSrc;

  libzip = fetchGithub "nih-at" "libzip" vpinballConfig.LIBZIP_SHA;

  openxr = fetchGithub "KhronosGroup" "OpenXR-SDK-Source" vpinballConfig.OPENXR_SHA;

  zlib = fetchGithub "madler" "zlib" vpinballConfig.ZLIB_SHA;

  libogg = fetchGithub "xiph" "ogg" vpinballConfig.LIBOGG_SHA;

  libopus = fetchGithub "xiph" "opus" vpinballConfig.LIBOPUS_SHA;

  opusfile = fetchGithub "xiph" "opusfile" vpinballConfig.OPUSFILE_SHA;

  libmysofa = fetchGithub "hoene" "libmysofa" vpinballConfig.LIBMYSOFA_SHA;

  libspatialaudio = fetchGithub "videolan" "libspatialaudio" vpinballConfig.LIBSPATIALAUDIO_SHA;

  pinmame-memmaps = fetchGithub "tomlogic" "pinball-memory-maps" vpinballConfig.PINMAME_MEMMAPS_SHA;

  pinmame-gamedefs = fetchGithub "vpinball" "pinmame-game-defs" vpinballConfig.PINMAME_GAMEDEFS_SHA;

  # Child dependencies declared in libdmdutil/platforms/config.sh
  libusb = fetchGithub "libusb" "libusb" libdmdutilConfig.LIBUSB_SHA;

  libzedmd = libzedmdSrc;

  libserum = fetchGithub "PPUC" "libserum" libdmdutilConfig.LIBSERUM_SHA;

  libpupdmd = fetchGithub "PPUC" "libpupdmd" libdmdutilConfig.LIBPUPDMD_SHA;

  libvni = fetchGithub "PPUC" "libvni" libdmdutilConfig.LIBVNI_SHA;

  # Child dependencies declared in libdof/platforms/config.sh
  libserialport = fetchGithub "sigrokproject" "libserialport" libdofConfig.LIBSERIALPORT_SHA;

  hidapi = fetchGithub "libusb" "hidapi" libdofConfig.HIDAPI_SHA;

  libftdi = fetchGithub "jsm174" "libftdi" libdofConfig.LIBFTDI_SHA;

  # Child dependencies declared in libzedmd/platforms/config.sh
  cargs = fetchGithub "likle" "cargs" libzedmdConfig.CARGS_SHA;

  libframeutil = fetchGithub "ppuc" "libframeutil" libzedmdConfig.LIBFRAMEUTIL_SHA;

  sockpp = fetchGithub "fpagliughi" "sockpp" libzedmdConfig.SOCKPP_SHA;

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
