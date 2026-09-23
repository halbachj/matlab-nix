{
  description = "MATLAB packaging for Nix: MPM downloads, install, and FHS GUI wrappers";

  inputs = {
    nixpkgs     .url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils .url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    {
      # Public named product catalog (release-independent).
      matlabProducts = import ./lib/matlabProducts.nix;

      # NixOS module providing `programs.matlab`. Product selection, release
      # compatibility, duplicate selections, and dependency-closure completeness
      # are validated at evaluation time.
      nixosModules.matlab = import ./modules/matlab.nix;
    }
    // flake-utils.lib.eachSystem [ "x86_64-linux" ] (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
        lib = nixpkgs.lib;

        matlabLibs = import ./lib/common.nix { inherit pkgs; };
        productMetadata = import ./lib/products.nix;
        matlabProducts = import ./lib/matlabProducts.nix;
        mpm = import ./modules/mpm.nix { inherit pkgs; };
        fetchMpm = import ./lib/fetchMpm.nix { inherit pkgs mpm; };
        installMatlab = import ./lib/install.nix { inherit pkgs; };
        serviceHost = import ./lib/serviceHost.nix { inherit pkgs; };
        fhsWrappers = import ./lib/fhs.nix { inherit pkgs matlabLibs; };

        # Resolve a configured `programs.matlab` and return the raw install tree
        # plus all FHS wrappers for it.
        makePackages = config:
          let
            cfg = config.programs.matlab;
            release = cfg.release;
            checksum = cfg.releaseMetadata.checksum;
            closureProducts = cfg.closureProducts;
            selectedNames = map (p: p.name) cfg.selectedProducts;

            mpmSources = map (product: fetchMpm {
              inherit release;
              hash = product.hash;
              product = product.name;
            }) closureProducts;
            matlabRaw = installMatlab {
              inherit release checksum closureProducts selectedNames;
              sources = mpmSources;
            };
            shrelease = "2025.3.0.2";
            shRaw = serviceHost;

            wrappers = fhsWrappers {
              inherit matlabRaw;
              serviceHost = shRaw;
              inherit shrelease;
              enableConnector = cfg.connector.enable;
            };
          in
          wrappers // { matlabRaw = matlabRaw; serviceHostRaw = shRaw; };

        # Default configuration: minimal package, MATLAB only.
        defaultCfg = lib.evalModules {
          modules = [
            ./modules/matlab.nix
            {
              programs.matlab = {
                release = "R2026a";
                installedProducts = [ "matlab" ];
              };
            }
          ];
          specialArgs = { inherit matlabProducts productMetadata; };
        };
        defaultPackages = makePackages defaultCfg.config;

        # Example configuration: MATLAB + Simulink.
        simulinkCfg = lib.evalModules {
          modules = [
            ./modules/matlab.nix
            {
              programs.matlab = {
                release = "R2026a";
                installedProducts = [ "matlab" "simulink" ];
              };
            }
          ];
          specialArgs = { inherit matlabProducts productMetadata; };
        };
        simulinkPackages = makePackages simulinkCfg.config;

        # Example configuration: MATLAB + Simulink + optional toolboxes.
        toolboxesCfg = lib.evalModules {
          modules = [
            ./modules/matlab.nix
            {
              programs.matlab = {
                release = "R2026a";
                installedProducts = [ "matlab" "simulink" "imageProcessing" "signalProcessing" ];
              };
            }
          ];
          specialArgs = { inherit matlabProducts productMetadata; };
        };
        toolboxesPackages = makePackages toolboxesCfg.config;

        mkMeta = pname: description: extra: {
          inherit pname description;
          license = lib.licenses.unfree;
          platforms = [ "x86_64-linux" ];
          # MATLAB artifacts are downloaded directly from MathWorks at build time;
          # this project publishes no binary cache.
          extra = extra;
        };
        attachMeta = pkg: pname: description: extra:
          pkg // { meta = mkMeta pname description extra; };
      in {
        packages = {
          # Minimal default package: MATLAB only.
          default = attachMeta defaultPackages.matlab "matlab"
            "MATLAB via MPM under an FHS sandbox (minimal default)" { };
          matlab = attachMeta defaultPackages.matlab "matlab"
            "MATLAB via MPM under an FHS sandbox" { };
          matlabRaw = attachMeta defaultPackages.matlabRaw "matlab-raw"
            "Raw MATLAB install tree from MPM sources" { };
          serviceHost = attachMeta defaultPackages.serviceHost "matlab-service-host"
            "MathWorks Service Host under an FHS sandbox" { };
          serviceHostWindow = attachMeta defaultPackages.serviceHostWindow "matlab-service-host-window"
            "MathWorks Service Host window under an FHS sandbox" { };
          # MATLAB + Simulink example.
          matlabWithSimulink = attachMeta simulinkPackages.matlab "matlab-with-simulink"
            "MATLAB + Simulink example package" { };
          # MATLAB + Simulink + optional toolboxes example.
          matlabWithToolboxes = attachMeta toolboxesPackages.matlab "matlab-with-toolboxes"
            "MATLAB + Simulink + image/signal processing toolboxes" { };
          # Experimental: MATLAB Connector. Not part of the minimal default;
          # requires the Service Host and additional license entitlements.
          connector = attachMeta defaultPackages.connector "matlab-connector"
            "EXPERIMENTAL MATLAB Connector wrapper" { experimental = true; };
        };

        checks = import ./tests/checks.nix {
          inherit pkgs lib matlabProducts productMetadata;
        };

        devShells.default = mpm.fhs.env;
        devShells.matlab = defaultPackages.matlab;
        devShells.serviceHost = defaultPackages.serviceHost;
      });
}
