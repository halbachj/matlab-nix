# Ready-to-use plugin definitions for programs.matlab.plugins.
{ pkgs }:
{
  matlab2tikz = {
    source = pkgs.fetchFromGitHub {
      owner = "matlab2tikz";
      repo = "matlab2tikz";
      # v1.1.0, pinned to the release commit.
      rev = "816f8754804cd45d8b41b3adf3ff9709a29cf173";
      hash = "sha256-GJl4hyd8gpvMiQfD0+NlZiT0OnrMnbMGOq1Kn0vlWQE=";
    };
    paths = [ "src" ];
  };
}
