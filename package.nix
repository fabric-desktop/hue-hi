{ stdenv

, meson
, ninja

, pkg-config
, vala

, hueadm

, glib
, gtk4
, libgee
, json-glib
, fabric-ui
}:

stdenv.mkDerivation {
  pname = "hue-hi";
  version = "0.1";

  src = ./.;

  buildInputs = [
    glib
    gtk4
    json-glib
    libgee
    fabric-ui
  ];

  postPatch = ''
    substituteInPlace ./src/models/models.vala \
      --replace 'const string HUEADM = "hueadm";' 'const string HUEADM = "${hueadm}/bin/hueadm";'
  '';

  nativeBuildInputs = [
    meson
    ninja

    pkg-config
    vala
  ];
}
