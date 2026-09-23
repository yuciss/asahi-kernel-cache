{
  description = "Standalone linux-asahi kernel build for caching";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable-small";
    apple-silicon-support = {
      url = "github:nix-community/nixos-apple-silicon";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, apple-silicon-support }:
    let
      system = "aarch64-linux";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ apple-silicon-support.overlays.default ];
      };
    in {
      packages.${system}.linux-asahi = pkgs.linux-asahi;
    };
}
