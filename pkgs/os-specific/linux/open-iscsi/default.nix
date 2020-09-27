{ lib, stdenv, fetchFromGitHub, automake, autoconf, libtool, gettext, bash
, util-linux, open-isns, openssl, kmod, perl, systemd, pkgconf
}:

stdenv.mkDerivation rec {
  pname = "open-iscsi";
  version = "2.1.3";

  nativeBuildInputs = [ autoconf automake gettext libtool perl pkgconf ];
  buildInputs = [ kmod open-isns.lib openssl systemd util-linux ];

  src = fetchFromGitHub {
    owner = "open-iscsi";
    repo = "open-iscsi";
    rev = version;
    sha256 = "14rcf4xmrmz522z57sm8bb3mn79dqsdwz84rl6id84fgjbwbsp6b";
  };

  DESTDIR = "$(out)";

  NIX_LDFLAGS = "-lkmod -lsystemd";
  NIX_CFLAGS_COMPILE = "-DUSE_KMOD";

  postPatch = ''
    for u in etc/systemd/*; do
      substituteInPlace $u --replace /sbin $out/bin --replace /usr/bin/sh ${bash}/bin/sh
    done
  '';

  preConfigure = ''
    sed -i 's|/usr|/|' Makefile
  '';

  installFlags = [
    "install"
    "install_systemd"
  ];

  postInstall = ''
    make install_systemd
    cp usr/iscsistart $out/sbin/
    for f in $out/lib/systemd/system/*; do
      substituteInPlace $f --replace /sbin $out/bin
    done
    $out/sbin/iscsistart -v
  '';

  postFixup = ''
    sed -i "s|/sbin/iscsiadm|$out/bin/iscsiadm|" $out/bin/iscsi_fw_login
  '';

  meta = with lib; {
    description = "A high performance, transport independent, multi-platform implementation of RFC3720";
    license = licenses.gpl2Plus;
    homepage = "https://www.open-iscsi.com";
    platforms = platforms.linux;
    maintainers = with maintainers; [ cleverca22 zaninime ];
  };
}
