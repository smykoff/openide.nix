{ lib, stdenv, fetchurl, makeWrapper, autoPatchelfHook, undmg
, zlib, freetype, fontconfig, libxkbcommon, alsa-lib, libGL, libdrm, libgbm
, libx11, libxext, libxi, libxrender, libxtst, libxrandr
, libxcursor, libxxf86vm, libxcb
, gtk3, glib, nss, nspr, at-spi2-core, cups, libsecret
, krb5, libxcrypt-legacy, lttng-ust_2_12, xz, expat, libnotify, libdbusmenu
, coreutils, gnugrep, gnused, which, git
}:

let
  inherit (stdenv.hostPlatform) system isLinux isDarwin;

  sources = builtins.fromJSON (builtins.readFile ./sources.json);
  platformSrc = sources.${system}
    or (throw "openide: unsupported system ${system}");

  runtimeLibs = [
    zlib freetype fontconfig libxkbcommon alsa-lib libGL libdrm libgbm
    libx11 libxext libxi libxrender libxtst libxrandr
    libxcursor libxxf86vm libxcb
    gtk3 glib nss nspr at-spi2-core cups libsecret libnotify
  ];
in
stdenv.mkDerivation {
  pname = "openide";
  version = sources.version;

  src = fetchurl { inherit (platformSrc) url hash; };

  nativeBuildInputs = [ makeWrapper ]
    ++ lib.optionals isLinux [ autoPatchelfHook ]
    ++ lib.optionals isDarwin [ undmg ];

  buildInputs = lib.optionals isLinux (runtimeLibs ++ [
    stdenv.cc.cc.lib krb5 libxcrypt-legacy lttng-ust_2_12 xz expat libdbusmenu
  ]);

  autoPatchelfIgnoreMissingDeps = true;

  dontFixup = isDarwin;
  dontBuild = true;
  sourceRoot = ".";

  unpackPhase =
    if isLinux then ''
      mkdir src && tar -xzf $src -C src --strip-components=1
    '' else ''
      undmg $src
    '';

  installPhase = ''
    runHook preInstall
  '' + (if isLinux then ''
    mkdir -p $out/opt/openide $out/bin
    cp -a src/. $out/opt/openide/

    makeWrapper $out/opt/openide/bin/openide.sh $out/bin/openide \
      --unset JAVA_TOOL_OPTIONS \
      --unset _JAVA_OPTIONS \
      --unset JDK_JAVA_OPTIONS \
      --prefix PATH : ${lib.makeBinPath [ coreutils gnugrep gnused which git ]} \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath runtimeLibs}
  '' else ''
    mkdir -p $out/Applications $out/bin
    cp -a *.app $out/Applications/

    exe=$(find $out/Applications/*.app/Contents/MacOS -type f -perm -u+x | head -n1)
    ln -s "$exe" $out/bin/openide
  '') + ''
    runHook postInstall
  '';

  meta = {
    description = "OpenIDE (IntelliJ-based IDE)";
    homepage = "https://openide.ru";
    platforms = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    mainProgram = "openide";
  };
}
