# Named, release-independent product catalog exposed as the public `matlabProducts`
# set. Each value is the *metadata key* of a product in a release's `products`
# table (see lib/products.nix). Because the catalog is keyed by product name, it
# can be reused across releases; release compatibility is validated when a product
# is selected for a specific release (see modules/matlab.nix).
{
  matlab = "MATLAB";
  simulink = "Simulink";
  imageProcessing = "Image_Processing_Toolbox";
  signalProcessing = "Signal_Processing_Toolbox";
  statisticsAndMachineLearning = "Statistics_and_Machine_Learning_Toolbox";
  symbolicMath = "Symbolic_Math_Toolbox";
  dspSystem = "DSP_System_Toolbox";
  audio = "Audio_Toolbox";
  controlSystem = "Control_System_Toolbox";
  systemIdentification = "System_Identification_Toolbox";
  simscape = "Simscape";
  simscapeElectrical = "Simscape_Electrical";
  communications = "Communications_Toolbox";
  fiveG = "5G_Toolbox";
  lte = "LTE_Toolbox";
  wlan = "WLAN_Toolbox";
  bluetooth = "Bluetooth_Toolbox";
  satelliteCommunications = "Satellite_Communications_Toolbox";
  rf = "RF_Toolbox";
  antenna = "Antenna_Toolbox";
  wirelessNetwork = "Wireless_Network_Toolbox";
  matlabCoder = "MATLAB_Coder";
  simulinkCoder = "Simulink_Coder";
  uav = "UAV_Toolbox";
}
