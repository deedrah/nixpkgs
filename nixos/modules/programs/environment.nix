# This module defines a standard configuration for NixOS global environment.

# Most of the stuff here should probably be moved elsewhere sometime.

{ config, lib, ... }:

with lib;

let

  cfg = config.environment;

in

{

  config = {

    environment.variables =
      { NIXPKGS_CONFIG = "/etc/nix/nixpkgs-config.nix";
        PAGER = mkDefault "less -R";
        EDITOR = mkDefault "nano";
        XCURSOR_PATH = [ "$HOME/.icons" ];
      };

    environment.profiles = mkAfter
      [ "/nix/var/nix/profiles/default"
        "/run/current-system/sw"
      ];

    # TODO: move most of these elsewhere
    environment.profileRelativeEnvVars =
      { PATH = [ "/bin" ];
        INFOPATH = [ "/info" "/share/info" ];
        KDEDIRS = [ "" ];
        STRIGI_PLUGIN_PATH = [ "/lib/strigi/" ];
        QT_PLUGIN_PATH = [ "/lib/qt4/plugins" "/lib/kde4/plugins" ];
        QTWEBKIT_PLUGIN_PATH = [ "/lib/mozilla/plugins/" ];
        GTK_PATH = [ "/lib/gtk-2.0" "/lib/gtk-3.0" ];
        XDG_CONFIG_DIRS = [ "/etc/xdg" ];
        XDG_DATA_DIRS = [ "/share" ];
        MOZ_PLUGIN_PATH = [ "/lib/mozilla/plugins" ];
        LIBEXEC_PATH = [ "/lib/libexec" ];
      };

    environment.extraInit =
      ''
         export NIX_USER_PROFILE_DIR="/nix/var/nix/profiles/per-user/$USER"
         export NIX_PROFILES="${concatStringsSep " " (reverseList cfg.profiles)}"
      '';

  };

}
