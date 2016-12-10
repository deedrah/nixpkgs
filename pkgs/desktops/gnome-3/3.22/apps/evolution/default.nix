{ stdenv, intltool, fetchurl, libxml2, webkitgtk, highlight
, pkgconfig, gtk3, glib, libnotify, gtkspell3
, wrapGAppsHook, itstool, shared_mime_info, libical, db, gcr, sqlite
, gnome3, librsvg, gdk_pixbuf, libsecret, nss, nspr, icu, libtool
, libcanberra_gtk3, bogofilter, gst_all_1, procps, p11_kit, dconf
, plugins, symlinkJoin, makeWrapper
}:

let
  majVer = gnome3.version;
  unwrapped = stdenv.mkDerivation rec {
  inherit (import ./src.nix fetchurl) name src;

  doCheck = true;

  propagatedUserEnvPkgs = [ gnome3.gnome_themes_standard
                            gnome3.evolution_data_server ];

  propagatedBuildInputs = [ gnome3.gtkhtml ];

  buildInputs = [ gtk3 glib intltool itstool libxml2 libtool
                  gdk_pixbuf gnome3.defaultIconTheme librsvg db icu
                  gnome3.evolution_data_server libsecret libical gcr
                  webkitgtk shared_mime_info gnome3.gnome_desktop gtkspell3
                  libcanberra_gtk3 bogofilter gnome3.libgdata sqlite
                  gst_all_1.gstreamer gst_all_1.gst-plugins-base p11_kit
                  nss nspr libnotify procps highlight gnome3.libgweather
                  gnome3.gsettings_desktop_schemas dconf
                  gnome3.libgnome_keyring gnome3.glib_networking ];

  nativeBuildInputs = [ pkgconfig wrapGAppsHook ];

  configureFlags = [ "--disable-spamassassin" "--disable-pst-import" "--disable-autoar"
                     "--disable-libcryptui" ];

  patches = [
    ./evolution-plugin-path.patch
    ./evolution-composite-cell-style.patch
    ./evolution-persistent-folder-ids.patch
    ./evolution-repeat-cursod-uid-restore.patch
    ./evolution-single-key-mark-read.patch
    ./evolution-mark-read-and-next-unread.patch
  ];

  NIX_CFLAGS_COMPILE = "-I${nss.dev}/include/nss -I${glib.dev}/include/gio-unix-2.0";

  enableParallelBuilding = true;

  preFixup = ''
    for f in $out/bin/* $out/libexec/*; do
      wrapProgram "$f" \
        --set GDK_PIXBUF_MODULE_FILE "$GDK_PIXBUF_MODULE_FILE" \
        --prefix XDG_DATA_DIRS : "${gnome3.gnome_themes_standard}/share:$XDG_ICON_DIRS:$GSETTINGS_SCHEMAS_PATH"
    done
  '';

  requiredSystemFeatures = [ "big-parallel" ];

  meta = with stdenv.lib; {
    homepage = https://wiki.gnome.org/Apps/Evolution;
    description = "Personal information management application that provides integrated mail, calendaring and address book functionality";
    maintainers = gnome3.maintainers;
    license = licenses.lgpl2Plus;
    platforms = platforms.linux;
  };
};

in if plugins == [] then unwrapped
    else import ./wrapper.nix {
      inherit stdenv makeWrapper symlinkJoin plugins;
      evolution = unwrapped;
      version = gnome3.version;
    }
