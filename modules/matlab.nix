{ lib, ... }:

{
  options.matlab = {
    release = lib.mkOption {
      type = lib.types.str;
      example = "R2026a";
      description = "MATLAB release to download with MPM.";
    };

    products = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "MATLAB" ];
      example = [ "MATLAB" "Simulink" "Image_Processing_Toolbox" ];
      description = ''
        MPM product identifiers to install, using underscores in multiword
        names. Every product must be available for the
        configured release and licensed for the signed-in MathWorks account.
      '';
    };
  };
}
