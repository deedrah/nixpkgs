{ stdenv, makeDesktopItem, freetype, fontconfig, libX11, libXrender
, zlib, jdk, glib, gtk, libXtst, gsettings_desktop_schemas, webkitgtk
, makeWrapper, ... }:

{ name, src ? builtins.getAttr stdenv.system sources, sources ? null, description }:

stdenv.mkDerivation rec {
  inherit name src;

  desktopItem = makeDesktopItem {
    name = "Eclipse";
    exec = "eclipse";
    icon = "eclipse";
    comment = "Integrated Development Environment";
    desktopName = "Eclipse IDE";
    genericName = "Integrated Development Environment";
    categories = "Application;Development;";
  };

  buildInputs = [
    fontconfig freetype glib gsettings_desktop_schemas gtk jdk libX11
    libXrender libXtst makeWrapper zlib
  ] ++ stdenv.lib.optional (webkitgtk != null) webkitgtk;

  buildCommand = ''
    # Unpack tarball.
    mkdir -p $out
    tar xfvz $src -C $out

    sed -i 's/url(.\/gtkTSFrame.png)/null/' $out/eclipse/plugins/*ui.themes*/css/e4_default_gtk.css

    # Patch binaries.
    interpreter=$(echo ${stdenv.glibc.out}/lib/ld-linux*.so.2)
    libCairo=$out/eclipse/libcairo-swt.so
    patchelf --set-interpreter $interpreter $out/eclipse/eclipse
    [ -f $libCairo ] && patchelf --set-rpath ${stdenv.lib.makeLibraryPath [ freetype fontconfig libX11 libXrender zlib ]} $libCairo

    # Create wrapper script.  Pass -configuration to store
    # settings in ~/.eclipse/org.eclipse.platform_<version> rather
    # than ~/.eclipse/org.eclipse.platform_<version>_<number>.
    productId=$(sed 's/id=//; t; d' $out/eclipse/.eclipseproduct)
    productVersion=$(sed 's/version=//; t; d' $out/eclipse/.eclipseproduct)

    makeWrapper $out/eclipse/eclipse $out/bin/eclipse \
      --prefix PATH : ${jdk}/bin \
      --prefix LD_LIBRARY_PATH : ${stdenv.lib.makeLibraryPath ([ glib gtk libXtst ] ++ stdenv.lib.optional (webkitgtk != null) webkitgtk)} \
      --prefix XDG_DATA_DIRS : "$GSETTINGS_SCHEMAS_PATH" \
      --add-flags "-configuration \$HOME/.eclipse/''${productId}_$productVersion/configuration"

    # Create desktop item.
    mkdir -p $out/share/applications
    cp ${desktopItem}/share/applications/* $out/share/applications
    mkdir -p $out/share/pixmaps
    ln -s $out/eclipse/icon.xpm $out/share/pixmaps/eclipse.xpm
  ''; # */

  meta = {
    homepage = http://www.eclipse.org/;
    inherit description;
  };

}
