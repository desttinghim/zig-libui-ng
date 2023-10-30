{
  description = "Zig bindings for libui-ng";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    zig-overlay.url = "github:mitchellh/zig-overlay";
    flake-utils.url = "github:numtide/flake-utils"; 
  };

  outputs = { self, nixpkgs, flake-utils, zig-overlay }:
    flake-utils.lib.eachSystem ["x86_64-linux"]
      (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          zig = zig-overlay.packages.${system};
        in
        {
          devShells = {
            default = pkgs.mkShell {
              buildInputs = [
                zig.master-2023-10-16
                pkgs.pkg-config
                pkgs.gtk3
                pkgs.gdb
              ];
            }; 
          };
        }
      );
}
