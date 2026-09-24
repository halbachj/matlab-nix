# NixOS module defining `programs.matlab`. Product selection, release
# compatibility, duplicate selections, and dependency-closure completeness are
# validated at evaluation time.
#
# `matlabProducts` and `productMetadata` are imported from this repository's
# source tree by default, so the module can be imported into any NixOS
# configuration without specialArgs. Passing either via specialArgs or
# `_module.args` overrides the default.

{ lib, config, ... } @ args:

let
  matlabProducts = args.matlabProducts or (import ../lib/matlabProducts.nix);
  productMetadata = args.productMetadata or (import ../lib/products.nix);
  catalogNames = lib.attrNames matlabProducts;
in
{
  options.programs.matlab = {
    release = lib.mkOption {
      type = lib.types.str;
      example = "R2026a";
      description = "MATLAB release to download and install with MPM.";
    };

    installedProducts = lib.mkOption {
      type = lib.types.listOf (lib.types.enum catalogNames);
      default = [ "matlab" ];
      description = ''
        Named products (keys of `matlabProducts`) to install for the configured
        release. Each selection is validated during evaluation for:
          - a known key in `matlabProducts`,
          - availability in the configured release's product metadata,
          - duplicate selections, and
          - a complete dependency closure within that release's metadata.
      '';
      example = [ "matlab" "simulink" "imageProcessing" ];
    };

    sourceHash = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Fixed-output hash of the MPM download for this product selection and
        its dependency closure. Required when selecting more than MATLAB.
      '';
    };

    connector = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          EXPERIMENTAL: build and expose the MATLAB Connector wrapper. MATLAB
          Connector requires the MathWorks Service Host and additional license
          entitlements; it is not enabled by default.
        '';
      };
    };

    # Derived, validated values consumed by packaging. Declared as options so the
    # module system accepts them; they are computed from `release` and
    # `installedProducts` and are not meant to be set directly.
    releaseMetadata = lib.mkOption {
      type = lib.types.attrs;
      internal = true;
      description = "Validated release metadata entry (internal).";
    };
    selectedProducts = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      internal = true;
      description = "Validated, deduplicated selected product entries (internal).";
    };
    closureProducts = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      internal = true;
      description = "Validated dependency-closure product entries (internal).";
    };
  };

  config.programs.matlab = let
    cfg = config.programs.matlab;

    relMeta = productMetadata.${cfg.release} or (throw
      "release `${cfg.release}' is not defined in lib/products.nix");

    relIndex = relMeta.products;

    # Map each named catalog key to its release metadata entry, rejecting keys
    # that are not available in the configured release.
    selectedEntries = map (key:
      let
        name = matlabProducts.${key} or (throw
          "product key `${key}' is not defined in lib/matlabProducts.nix");
      in
      relIndex.${name} or (throw
        "product `${name}' is not available in release `${cfg.release}'")
    ) cfg.installedProducts;

    # Reject duplicate selections. `foldl` forces the throw on the first
    # repeated product name.
    checkedEntries = lib.foldl (acc: p:
      if lib.elem p.name acc.names then
        throw "product `${p.name}' is selected more than once in programs.matlab.installedProducts"
      else
        acc // { names = acc.names ++ [ p.name ]; entries = acc.entries ++ [ p ]; })
      { names = [ ]; entries = [ ]; }
      selectedEntries;
    selectedProducts = checkedEntries.entries;

    # Closure of each selected product, validating that every dependency is
    # present in the release metadata.
    closure = product:
      [ product ] ++ lib.concatMap (dep:
        let depEntry = relIndex.${dep} or (throw
          "dependency `${dep}' of product `${product.name}' is missing from release `${cfg.release}' metadata");
        in closure depEntry
      ) product.dependencies;
    closureProducts = lib.unique (lib.concatMap closure selectedProducts);
  in {
    releaseMetadata = relMeta;
    selectedProducts = selectedProducts;
    closureProducts = closureProducts;
  };
}
