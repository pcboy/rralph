{
  description = "A basic flake with a shell";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.systems.url = "github:nix-systems/default";
  inputs.flake-utils = {
    url = "github:numtide/flake-utils";
    inputs.systems.follows = "systems";
  };

  outputs =
    { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        ruby = pkgs.ruby_3_4;
        gems = pkgs.bundlerEnv {
          name = "agroapi-env";
          ruby = ruby;

          gemdir = ./.;

          groups = [
            "default"
            "production"
            "development"
            "test"
          ];

          gemConfig = pkgs.defaultGemConfig;
        };
      in
      {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            gems
            (lib.lowPrio gems.wrappedRuby)
            (gems.ruby.withPackages (
              ps: with ps; [
                bump
                ruby-lsp
              ]
            ))
            (bundix.override {
              bundler = bundler.override {
                ruby = gems.ruby;
              };
            })
            pkgs.bashInteractive
          ];
        };
      }
    );
}
