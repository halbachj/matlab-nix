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
}
