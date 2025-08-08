{
  description = "Nix DevShell Flake Templates";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs @ {
    nixpkgs,
    flake-parts,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = [
        "x86_64-linux" # 64bit Intel/AMD Linux
        "x86_64-darwin" # 64bit Intel Darwin (macOS)
        "aarch64-linux" # 64bit ARM Linux
        "aarch64-darwin" # 64bit ARM Darwin (macOS)
      ];

      perSystem = {
        self',
        inputs',
        system,
        pkgs,
        config,
        ...
      }: {
        formatter = pkgs.alejandra;

        # Define a devShell with packages that are useful for templates
        devShells.default = pkgs.mkShell {
          name = "templates";
          buildInputs = [
            pkgs.gnumake
            pkgs.just
            pkgs.jq
          ];
        };
      };

      flake = {
        templates = {
          # flyte-local-sandbox = { # TODO: implement this
          #   description = "Local Flyte Sandbox";
          #   path = ./flyte/...;
          # };
        };
      };
    };
}
