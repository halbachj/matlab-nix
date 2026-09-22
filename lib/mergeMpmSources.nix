{ pkgs }:

{ release, checksum, products, sources }:
assert builtins.length products == builtins.length sources;
let
  lib = pkgs.lib;
  productCodes = lib.concatMapStringsSep "\n" (product: "    <product>${product.productCode}</product>")
    (lib.sort (a: b: a.productCode < b.productCode) products);
  sourcePaths = lib.concatStringsSep " " (map toString sources);
in
pkgs.runCommand "mpm-${release}-source" { nativeBuildInputs = [ pkgs.coreutils pkgs.findutils ]; } ''
  mkdir -p "$out/archives/glnxa64" "$out/mpm"
  for source in ${sourcePaths}; do
    for directory in archives mpm; do
      while IFS= read -r file; do
        relative="''${file#"$source/$directory/"}"
        target="$out/$directory/$relative"
        mkdir -p "$(dirname "$target")"
        if [ -e "$target" ]; then
          cmp --quiet "$file" "$target" || {
            echo "conflicting MPM $directory file: $relative" >&2
            exit 1
          }
        else
          ln -s "$file" "$target"
        fi
      done < <(find "$source/$directory" -type f)
    done
  done

  cat > "$out/ProductFilesInfo.xml" <<'EOF'
  <?xml version="1.0" encoding="utf-8"?>
  <product_files_info>
    <release>${release}</release>
    <status>Release</status>
    <update_level>5</update_level>
    <checksum>${checksum}</checksum>
    <available_products>
  ${productCodes}
    </available_products>
  </product_files_info>
  EOF
''
