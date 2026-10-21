{ pkgs ? import <nixpkgs> { } }:

let
  # Newer patchelf versions produce overlapping LOAD segments in the upstream binary.
  patchelf = pkgs.patchelf.overrideAttrs (_: {
    version = "0.15.2";
    src = pkgs.fetchurl {
      url = "https://github.com/NixOS/patchelf/releases/download/0.15.2/patchelf-0.15.2.tar.bz2";
      hash = "sha256-F3RfVkFZyOIo/EEtplogSLhGxLa0Igt3y/IkFuAvLXw=";
    };
    patches = [ ];
  });
  sources = builtins.fromJSON (builtins.readFile ./sources.json);
  srcConfig =
    sources.${pkgs.stdenv.hostPlatform.system}
      or (throw "Unsupported system: ${pkgs.stdenv.hostPlatform.system}");
in
pkgs.stdenv.mkDerivation rec {
  pname = "github-copilot-cli";
  inherit (sources) version;

  src = pkgs.fetchurl {
    url = "https://github.com/github/copilot-cli/releases/download/v${version}/${srcConfig.name}.tar.gz";
    inherit (srcConfig) hash;
  };

  buildInputs = pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.stdenv.cc.cc.lib ];
  sourceRoot = ".";
  dontStrip = true;
  dontPatchELF = true;

  postFixup = pkgs.lib.optionalString pkgs.stdenv.hostPlatform.isLinux ''
    ${patchelf}/bin/patchelf \
      --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
      --set-rpath "${pkgs.lib.makeLibraryPath [ pkgs.stdenv.cc.cc.lib ]}" \
      $out/bin/copilot
  '';

  doInstallCheck = pkgs.stdenv.buildPlatform.canExecute pkgs.stdenv.hostPlatform;
  installCheckPhase = ''
    runHook preInstallCheck
    $out/bin/copilot --version
    runHook postInstallCheck
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 copilot $out/bin/copilot
    runHook postInstall
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
