{
  R2026a = {
    checksum = "3341262710";
    products = {
      MATLAB = {
        name = "MATLAB";
        productCode = "ML";
        hash = "sha256-m7ZU9XfCUikpeuoRMJ+e7DIZ0fJGsLsXpOCgtlKSvaQ=";
        dependencies = [ ];
      };

      Simulink = {
        name = "Simulink";
        productCode = "SL";
        hash = "sha256-s5Q3LQWNL5n35LX5bN9UMDaViY4w/dBI+m9oQzhHj+o=";
        dependencies = [ "MATLAB" ];
      };

      Image_Processing_Toolbox = {
        name = "Image_Processing_Toolbox";
        productCode = "IP";
        hash = "sha256-LF7IQ7Ggp1it7lTTkeH4gxionNGmigmKzZn2spHc76U=";
        dependencies = [ "MATLAB" ];
      };

      Signal_Processing_Toolbox = {
        name = "Signal_Processing_Toolbox";
        productCode = "SG";
        hash = "sha256-ciFUyCPi4gya02zU7zD7jcV8k6kjT5dD3SQZ4gOArOc=";
        dependencies = [ "MATLAB" ];
      };
    };
  };
}
