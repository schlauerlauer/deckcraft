{
  description = "DeckCraft Rust development environment";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs, ... }:
    let
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          deckcraft-cli = pkgs.rustPlatform.buildRustPackage {
            pname = "deckcraft-cli";
            version = "0.6.1";
            src = self;
            cargoLock.lockFile = ./Cargo.lock;
            cargoBuildFlags = [ "-p" "deckcraft-cli" ];
            doCheck = false;
            installPhase = ''
              runHook preInstall
              install -Dm755 target/${pkgs.stdenv.hostPlatform.rust.rustcTarget}/release/deckcraft-cli $out/bin/deckcraft-cli
              runHook postInstall
            '';
          };
          deckcraft = pkgs.rustPlatform.buildRustPackage {
            pname = "deckcraft";
            version = "0.6.1";
            src = self;
            cargoLock.lockFile = ./Cargo.lock;
            cargoBuildFlags = [ "-p" "deckcraft" ];
            doCheck = false;
            installPhase = ''
              runHook preInstall
              install -Dm755 target/${pkgs.stdenv.hostPlatform.rust.rustcTarget}/release/deckcraft $out/bin/deckcraft
              runHook postInstall
            '';
          };
          default = self.packages.${system}.deckcraft-cli;
        });

      devShells = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
          linuxPackages = with pkgs; lib.optionals stdenv.isLinux [
            alsa-lib
            libGL
            libX11
            libXcursor
            libXi
            libXrandr
            libxkbcommon
            wayland
          ];
        in
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              cargo
              clippy
              pkg-config
              rust-analyzer
              rustc
              rustfmt
            ] ++ linuxPackages;
          };
        });
    };
}
