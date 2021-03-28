{
  description = "A very basic flake";
  inputs = {
    flake-utils.url = "github:numtide/flake-utils/master";
    smunix-monoid-extras.url = "github:smunix/monoid-extras/fix.diagrams";
    smunix-diagrams-core.url = "github:smunix/diagrams-core/fix.diagrams";
    smunix-diagrams-solve.url = "github:smunix/diagrams-solve/fix.diagrams";
  }; 
  outputs = { self, nixpkgs, flake-utils,
              smunix-diagrams-core, smunix-diagrams-solve, smunix-monoid-extras,
              ...
            }:
    with flake-utils.lib;
    with nixpkgs.lib;
    eachSystem [ "x86_64-linux" ] (system:
      let version = "${substring 0 8 self.lastModifiedDate}.${self.shortRev or "dirty"}";
          overlay = self: super:
            with self;
            with haskell.lib;
            with haskellPackages.extend (self: super: {
              inherit (smunix-diagrams-core.packages.${system}) diagrams-core;
              inherit (smunix-diagrams-solve.packages.${system}) diagrams-solve;
              inherit (smunix-monoid-extras.packages.${system}) diagrams-solve;
            });
            {
              diagrams-lib = rec {
                package = overrideCabal (callCabal2nix "diagrams-lib" ./. {}) (o: { version = "${o.version}-${version}"; });
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
