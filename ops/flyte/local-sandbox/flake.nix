{
  description = "Flyte Local Sandbox Template";

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
      }: let
        pythonPackages = pkgs.python311Packages;

        # Map system to flytectl architecture strings
        archMap = {
          "x86_64-linux" = "Linux_x86_64";
          "aarch64-linux" = "Linux_arm64";
          "x86_64-darwin" = "Darwin_x86_64";
          "aarch64-darwin" = "Darwin_arm64";
        };

        # Map system to SHA256 hashes
        hashMap = {
          "x86_64-linux" = "1bmhpwf961bm8vwnrq70rv6hfnss140gkj4mwpa1qs0xk79c8b8r";
          "aarch64-linux" = "0h2n631idxllzngcwxy4b2vjzzlp45cxz4z75ans4xbxlkdz1in2";
          "x86_64-darwin" = "1lg6c74qq2qci006dry21qf790n6y4i0pmi7s14d4dbm2sji293a";
          "aarch64-darwin" = "1s2vahsyclqm10sjby2773xgy4zq0zn9p2d0p71qcaamf14m9nk9";
        };

        arch = archMap.${system} or (throw "Unsupported system: ${system}");
        hash = hashMap.${system} or (throw "No hash available for system: ${system}");
        version = "v0.9.5";

        flytectl = pkgs.stdenv.mkDerivation rec {
          pname = "flytectl";
          version = "0.9.5";

          src = pkgs.fetchurl {
            url = "https://github.com/flyteorg/flyte/releases/download/flytectl%2F${version}/flytectl_${arch}.tar.gz";
            sha256 = hash;
          };

          sourceRoot = ".";

          installPhase = ''
            mkdir -p $out/bin
            cp flytectl $out/bin/
            chmod +x $out/bin/flytectl
          '';

          meta = with pkgs.lib; {
            description = "A command-line interface to Flyte";
            homepage = "https://github.com/flyteorg/flyte";
            license = licenses.asl20;
            maintainers = [];
            platforms = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
          };
        };
      in {
        _module.args.pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true; # allow unfree packages, i.e. cuda packages
        };

        devShells.default = pkgs.mkShell {
          name = "devshell";
          venvDir = "./.venv";
          buildInputs = [
            # Python
            pythonPackages.python # python interpreter
            pythonPackages.venvShellHook # venv hook for creating/activating

            # system packages to install to the environment
            pkgs.uv
            pkgs.ruff

            # Flyte tools
            flytectl
          ];

          # Run only after creating the virtual environment
          postVenvCreation = ''
            unset SOURCE_DATE_EPOCH
          '';

          # Run on each venv activation.
          postShellHook = ''
            unset SOURCE_DATE_EPOCH
            export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$NIX_LD_LIBRARY_PATH"
          '';
        };
      };
    };
}
