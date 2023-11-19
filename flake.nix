{
  description = "Processor for XSLT 3.0, XPath 2.0 and 3.1, and XQuery 3.1";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
    # saxon-he = {
    #   url = "https://github.com/Saxonica/Saxon-HE/raw/main/12/Java/SaxonHE12-3J.zip";
    #   flake = false;
    # };
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        lib = nixpkgs.lib;
        java = pkgs.temurin-jre-bin-11;
        version-major = "12";
        version-minor = "3";
      in {
        packages = {
          default = pkgs.stdenvNoCC.mkDerivation rec {
            pname = "saxon-he";
            version = "${version-major}.${version-minor}";

            nativeBuildInputs = with pkgs; [ unzip makeWrapper ];
            buildInputs = [ java ];

            src = builtins.fetchurl {
              url = "https://github.com/Saxonica/Saxon-HE/releases/download/SaxonHE${version-major}-${version-minor}/SaxonHE${version-major}-${version-minor}J.zip";
              sha256 = "3b69ea2f817cab49072f9e85dae5e01979515f2458844f7334d26025f5ec9418";
            };

            unpackPhase = ''
              unzip $src -d saxon
            '';

            installPhase = 
            let
              mainJar = "$out/share/java/saxon-he-${version}.jar";
              makeSaxonWrapper = name: class: ''
                makeWrapper ${java}/bin/java $out/bin/${name} \
                  --add-flags "-cp ${mainJar} ${class}"
              '';
            in
            ''
              mkdir -p $out/bin $out/share/java

              cp -r saxon/*.jar saxon/lib/ $out/share/java/
              cp -r saxon/doc/ $out/share/

              ${makeSaxonWrapper "saxon-xslt" "net.sf.saxon.Transform"}
              ${makeSaxonWrapper "saxon-xq" "net.sf.saxon.Query"}
            '';
          };
        };
      }
    );
}
