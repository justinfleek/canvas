{
  description = "Canvas - Universal Canvas Builder";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    purescript-overlay.url = "github:thomashoneyman/purescript-overlay";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      purescript-overlay,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ purescript-overlay.overlays.default ];
        };

        buildInputs = [
          pkgs.nodejs_22
          pkgs.purs
          pkgs.spago-unstable
          pkgs.esbuild
        ];

      in
      {
        devShells.default = pkgs.mkShell {
          inherit buildInputs;

          shellHook = ''
            echo "Canvas Builder dev shell"
            echo "  spago build    - Build PureScript"
          '';
        };
      }
    );
}
