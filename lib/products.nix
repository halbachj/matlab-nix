{
  R2026a = {
    checksum = "4252851421";
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

      Statistics_and_Machine_Learning_Toolbox = {
        name = "Statistics_and_Machine_Learning_Toolbox";
        productCode = "ST";
        hash = "sha256-MAqQr8S/xL6j16JfcVxon44nPlflqXFGsvZfnOXNuRE=";
        dependencies = [ "MATLAB" ];
      };

      Symbolic_Math_Toolbox = {
        name = "Symbolic_Math_Toolbox";
        productCode = "SM";
        hash = "sha256-lRb0FQIE1WZqZfMZLDfNSA0GyZWOG7gtw1QDDLxJa3w=";
        dependencies = [ "MATLAB" ];
      };

      DSP_System_Toolbox = {
        name = "DSP_System_Toolbox";
        productCode = "DS";
        hash = "sha256-X6YYgab+AUrgPYD2H/cirUSx8ZjDiXZFOI08da41i3Q=";
        dependencies = [ "MATLAB" "Signal_Processing_Toolbox" ];
      };

      Audio_Toolbox = {
        name = "Audio_Toolbox";
        productCode = "AU";
        hash = "sha256-5wb9UnXAAFdP2DhmcMVLuHeI2i0S33iGHVhBXHb1IMo=";
        dependencies = [ "MATLAB" "Signal_Processing_Toolbox" "DSP_System_Toolbox" ];
      };

      Control_System_Toolbox = {
        name = "Control_System_Toolbox";
        productCode = "CT";
        hash = "sha256-hVQ01YtHSFhWCrqDfj8RV5bpdPyXF35x21IlEMqD8YA=";
        dependencies = [ "MATLAB" ];
      };

      System_Identification_Toolbox = {
        name = "System_Identification_Toolbox";
        productCode = "ID";
        hash = "sha256-g1i9jTeILArJgMlR8WRLOJjA0o2OEmsa6r3gH1CdrGA=";
        dependencies = [ "MATLAB" ];
      };

      Simscape = {
        name = "Simscape";
        productCode = "SS";
        hash = "sha256-yzdd895itFwaZGbMsdX/LKoZeWh9O7UJV2u5Cjt37Hs=";
        dependencies = [ "MATLAB" "Simulink" ];
      };

      Simscape_Electrical = {
        name = "Simscape_Electrical";
        productCode = "PS";
        hash = "sha256-r4NCQNZpKvUdzwrrqPRP+pQZain84Wl7/icxUR7PmHc=";
        dependencies = [ "MATLAB" "Simulink" "Simscape" ];
      };

      Communications_Toolbox = {
        name = "Communications_Toolbox";
        productCode = "CM";
        hash = "sha256-MLo6NVklBtuSPC+4IJqEx7+QzsoR0I7zy5FjZeTL16k=";
        dependencies = [ "MATLAB" "Signal_Processing_Toolbox" "DSP_System_Toolbox" ];
      };

      "5G_Toolbox" = {
        name = "5G_Toolbox";
        productCode = "5G";
        hash = "sha256-Ykd7YCIfpm+QSDFA7rv7qDJNUzJgPOJ454gxoeolEeo=";
        dependencies = [ "MATLAB" "Signal_Processing_Toolbox" "DSP_System_Toolbox" "Communications_Toolbox" ];
      };

      LTE_Toolbox = {
        name = "LTE_Toolbox";
        productCode = "LS";
        hash = "sha256-DWVjStB4Zi/KPS7vQsvwpd1Cf50PbzXPmNhji8Mipx4=";
        dependencies = [ "MATLAB" "Signal_Processing_Toolbox" "DSP_System_Toolbox" "Communications_Toolbox" ];
      };

      WLAN_Toolbox = {
        name = "WLAN_Toolbox";
        productCode = "WL";
        hash = "sha256-daVy+mHTkHb38+ylR127/nZP8pv70Ge1mqswWFrjAYk=";
        dependencies = [ "MATLAB" "Signal_Processing_Toolbox" "DSP_System_Toolbox" "Communications_Toolbox" ];
      };

      Bluetooth_Toolbox = {
        name = "Bluetooth_Toolbox";
        productCode = "BL";
        hash = "sha256-pE1dc1Mnk52DQRgHOUkQTLRj6WeH8AXbnWyW5kLlBkI=";
        dependencies = [ "MATLAB" "Signal_Processing_Toolbox" "DSP_System_Toolbox" "Communications_Toolbox" ];
      };

      Satellite_Communications_Toolbox = {
        name = "Satellite_Communications_Toolbox";
        productCode = "SI";
        hash = "sha256-ILoYiY2mSYnhNJECLS0jgmxP+1zvJbEqEWZM7SaeWZ0=";
        dependencies = [ "MATLAB" "Signal_Processing_Toolbox" "DSP_System_Toolbox" "Communications_Toolbox" ];
      };

      RF_Toolbox = {
        name = "RF_Toolbox";
        productCode = "RF";
        hash = "sha256-bxtg6HKKdisgpq9t5TmkuWjTs3/9uOmjs3OT21moLFo=";
        dependencies = [ "MATLAB" ];
      };

      Antenna_Toolbox = {
        name = "Antenna_Toolbox";
        productCode = "AA";
        hash = "sha256-EBbBpkgB6Xjd7ADbdI2qC1ewSJurjNDR1ijwg3Koh4s=";
        dependencies = [ "MATLAB" ];
      };

      Wireless_Network_Toolbox = {
        name = "Wireless_Network_Toolbox";
        productCode = "WN";
        hash = "sha256-3CMprKWfSMiSmt4ci7OWmOghUbaRz8gXTrNt9xtFe0c=";
        dependencies = [ "MATLAB" "Signal_Processing_Toolbox" "DSP_System_Toolbox" "Communications_Toolbox" ];
      };

      MATLAB_Coder = {
        name = "MATLAB_Coder";
        productCode = "ME";
        hash = "sha256-fef3jeW/CRKyVh2eX0UkyIdUnGDQdk41uWeGiZ3WeoU=";
        dependencies = [ "MATLAB" ];
      };

      Simulink_Coder = {
        name = "Simulink_Coder";
        productCode = "RT";
        hash = "sha256-6jPD5adIJNzl+nF56cE3JgJ2aJwDXlUXS0CFUz+PGJs=";
        dependencies = [ "MATLAB" "Simulink" "MATLAB_Coder" ];
      };

      UAV_Toolbox = {
        name = "UAV_Toolbox";
        productCode = "UV";
        hash = "sha256-ct3QanNVkf7oyvEVR/IEh11WBpg4DLumxmP/gG6bhXw=";
        dependencies = [ "MATLAB" ];
      };
    };
  };
}
