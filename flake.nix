{
  description = "A very basic flake";
  inputs = {
    flake-utils.url = "github:numtide/flake-utils/master";
    smunix-monoid-extras.url = "github:smunix/monoid-extras/fix.diagrams";
    smunix-diagrams-core.url = "github:smunix/diagrams-core/fix.diagrams";
  }; 
  outputs = { self, nixpkgs, flake-utils, smunix-diagrams-core, ... }:
    with flake-utils.lib;
    with nixpkgs.lib;
    eachSystem [ "x86_64-darwin" ] (system:
      let version = "${substring 0 8 self.lastModifiedDate}.${self.shortRev or "dirty"}";
          overlay = self: super:
            with self;
            with haskell.lib;
            with haskellPackages;
            {
              diagrams-lib = rec {
                  package = overrideCabal (callCabal2nix "diagrams-lib" ./. {
                    inherit (smunix-diagrams-core.packages.${system}) diagrams-core;
                  }) (o: { version = "${o.version}-${version}"; });
                  bench = mkApp { drv = package; exePath = "/bin/benchmarks-exe";};
                };
            };
          overlays = [ overlay ];
      in
        with (import nixpkgs { inherit system overlays; });
        rec {
          packages = flattenTree (recurseIntoAttrs { diagrams-lib = diagrams-lib.package; });
          defaultPackage = packages.diagrams-lib;
          apps = {
            inherit (diagrams-lib) bench;
          };
          defaultApp = apps.bench;
        });
}
