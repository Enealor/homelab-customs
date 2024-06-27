{
  description = "caddy customized to use the cloudflare-dns plugin";

  inputs.nixpkgs.url = "nixpkgs/nixos-24.05";

  outputs =
    { self, nixpkgs }:
    let

      # to work with older version of flakes
      lastModifiedDate = self.lastModifiedDate or self.lastModified or "19700101";
      version = builtins.substring 0 8 lastModifiedDate;

      # consider versioning from caddy and dns
      # caddyVersion = "2.4.2";
      # caddyDnsCloudflareVersion = "20240610135444-d11ac0bfeab7";
      # version = "${caddyVersion}+cloudflare.${caddyDnsCloudflareVersion}";

      # System types to support.
      supportedSystems = [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      # Nixpkgs instantiated for supported system types.
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; });
    in
    {

      # Provide some binary packages for selected system types.
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgsFor.${system};
        in
        {
          caddy = pkgs.buildGoModule {
            pname = "caddy";
            inherit version;
            # In 'nix develop', we don't need a copy of the source tree
            # in the Nix store.
            src = ./.;
            ldflags = [ "-w" ];

            # This hash locks the dependencies of this package. It is
            # necessary because of how Go requires network access to resolve
            # VCS.  See https://www.tweag.io/blog/2021-03-04-gomod2nix/ for
            # details. Normally one can build with a fake hash and rely on native Go
            # mechanisms to tell you what the hash should be or determine what
            # it should be "out-of-band" with other tooling (eg. gomod2nix).
            # To begin with it is recommended to set this, but one must
            # remember to bump this hash when your dependencies change.
            # vendorHash = pkgs.lib.fakeHash;
            vendorHash = "sha256-AzrRZi1dGZLVx+1vW+jCNgwq/1YFQU+OaNlMjUj2bI0=";
          };
        }
      );

      # Add dependencies that are only needed for development
      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgsFor.${system};
        in
        {
          default = pkgs.mkShell { buildInputs = with pkgs; [ go ]; };
        }
      );

      # The default package for 'nix build'. This makes sense if the
      # flake provides only one package or there is a clear "main"
      # package.
      defaultPackage = forAllSystems (system: self.packages.${system}.caddy);
    };
}
