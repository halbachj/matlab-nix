# Build a checked set of plugin directory links, without touching the MATLAB
# install tree. Numeric links keep MATLABPATH independent of source filenames.
{ pkgs }:
plugins:
let
  lib = pkgs.lib;
  directories = lib.concatMap (plugin:
    map (path: "${plugin.source}/${path}") plugin.paths
  ) (lib.attrValues plugins);
  entries = lib.imap0 (index: source: {
    inherit source;
    name = toString index;
  }) directories;
  package = pkgs.runCommand "matlab-plugins" { } ''
    mkdir -p "$out"
    ${lib.concatMapStringsSep "\n" (entry: ''
      if [ ! -d ${lib.escapeShellArg entry.source} ]; then
        echo ${lib.escapeShellArg "MATLAB plugin directory does not exist: ${entry.source}"} >&2
        exit 1
      fi
      ln -s ${lib.escapeShellArg entry.source} "$out/${entry.name}"
    '') entries}
  '';
in
{
  inherit package;
  searchPath = lib.concatMapStringsSep ":" (entry: "${package}/${entry.name}") entries;
}
