{ pkgs ? import <nixpkgs> { } }:

let
  sources = builtins.fromJSON (builtins.readFile ./sources.json);
  srcConfig =
    sources.${pkgs.stdenv.hostPlatform.system}
      or (throw "Unsupported system: ${pkgs.stdenv.hostPlatform.system}");
in
pkgs.stdenv.mkDerivation rec {
  pname = "github-copilot-cli";
  inherit (sources) version;

  src = pkgs.fetchurl {
    url = "https://github.com/github/copilot-cli/releases/download/v${version}/${srcConfig.name}";
    inherit (srcConfig) hash;
  };

  nativeBuildInputs = [ pkgs.makeBinaryWrapper ]
    ++ pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.autoPatchelfHook ];
  buildInputs = pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [
    pkgs.stdenv.cc.cc.lib
    pkgs.glib
    pkgs.libsecret
    pkgs.openssl
  ];
  # Native addons load OpenSSL dynamically, so DT_NEEDED scanning is insufficient.
  runtimeDependencies = pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [
    (pkgs.lib.getLib pkgs.openssl)
  ];
  sourceRoot = "package";
  dontStrip = true;

  # Optional GUI, screen-capture, and local-inference features, as in nixpkgs.
  autoPatchelfIgnoreMissingDeps = [
    "libX11.so.6"
    "libXtst.so.6"
    "libjpeg.so.8"
    "libpng16.so.16"
    "libpipewire-0.3.so.0"
    "libei.so.1"
    "libwebkit2gtk-4.1.so.0"
    "libjavascriptcoregtk-4.1.so.0"
    "libgtk-3.so.0"
    "libgdk-3.so.0"
    "libcairo.so.2"
    "libgdk_pixbuf-2.0.so.0"
    "libsoup-3.0.so.0"
    "libwayland-client.so.0"
    "libdbus-1.so.3"
    "libxdo.so.3"
    "libonnxruntime-genai.so"
    "libonnxruntime.so.1"
  ];

  doInstallCheck = pkgs.stdenv.buildPlatform.canExecute pkgs.stdenv.hostPlatform;
  installCheckPhase = ''
    export HOME="$(mktemp -d)"
    runHook preInstallCheck
    $out/bin/copilot --version
    runHook postInstallCheck
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/lib/github-copilot-cli"
    cp -r . "$out/lib/github-copilot-cli"
    runHook postInstall
  '';

  postInstall = ''
    makeWrapper ${pkgs.nodejs}/bin/node "$out/bin/copilot" \
      --add-flag "$out/lib/github-copilot-cli/index.js" \
      --add-flag --no-auto-update \
      --set-default NODE_NO_WARNINGS 1 \
      --set-default SSL_CERT_DIR "${if pkgs.stdenv.hostPlatform.isLinux then "/etc/ssl/certs" else "${pkgs.cacert}/etc/ssl/certs"}" \
      --prefix PATH : "${pkgs.lib.makeBinPath [ pkgs.bash ]}"
  '';

  meta = with pkgs.lib; {
    description = "GitHub Copilot CLI - AI-powered coding agent in your terminal";
    homepage = "https://github.com/github/copilot-cli";
    changelog = "https://github.com/github/copilot-cli/releases/tag/v${version}";
    license = licenses.unfree;
    mainProgram = "copilot";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
  };
}
