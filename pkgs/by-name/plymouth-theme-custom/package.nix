{
  lib,
  stdenvNoCC,
  runCommandLocal,
  ffmpeg-headless,
  plymouth-theme-cat,
  # theme name for boot.plymouth.theme
  name ? "custom",
  # plymouth mode to animation, modes without one play boot.
  # an animation is a video, a gif or a folder of png frames, or
  # { intro = ...; loop = ...; } to play intro once before looping
  animations ? null,
  # frames per second taken from videos and played back
  fps ? 25,
  # scale frames to this width, every frame ends up in the initrd
  width ? null,
  background ? "#161616",
  text ? "#ffffff",
}:

let
  modes = [
    "boot"
    "shutdown"
    "reboot"
    "updates"
    "system-upgrade"
    "firmware-upgrade"
    "system-reset"
  ];

  # the password prompt images and the default animation come from the cat
  catDir = "${plymouth-theme-cat}/share/plymouth/themes/PlymouthTheme-Cat";

  cat = runCommandLocal "plymouth-cat-frames" { } ''
    mkdir $out
    cp ${catDir}/progress-*.png $out
  '';

  anims = if animations == null then { boot = cat; } else animations;

  parts =
    anim:
    if lib.isAttrs anim && !lib.isDerivation anim then
      anim
    else
      {
        loop = anim;
      };

  frames = lib.lists.concatLists (
    lib.attrsets.mapAttrsToList (
      mode: anim:
      lib.attrsets.mapAttrsToList (
        part: file: "frames ${lib.strings.escapeShellArg "${file}"} ${mode}-${part}"
      ) (parts anim)
    ) anims
  );

  validParts =
    anim:
    lib.lists.elem (lib.attrNames (parts anim)) [
      [ "loop" ]
      [
        "intro"
        "loop"
      ]
    ];

  isColor = c: builtins.match "#[0-9a-fA-F]{6}" c != null;
  rgb =
    prefix: c:
    lib.strings.concatImapStrings
      (
        i: channel:
        "${prefix}_${channel} = ${
          toString (lib.trivial.fromHexString (builtins.substring (i * 2 - 1) 2 c) / 255.0)
        };\n"
      )
      [
        "red"
        "green"
        "blue"
      ];

  scale = lib.strings.optionalString (width != null) ",scale=${toString width}:-1";
in

assert lib.assertMsg (anims ? boot) "plymouth-theme-custom: animations needs a boot entry";
assert lib.assertMsg (lib.lists.all (m: lib.lists.elem m modes) (lib.attrNames anims))
  "plymouth-theme-custom: animation modes must be in ${lib.strings.concatStringsSep ", " modes}, got ${lib.strings.concatStringsSep ", " (lib.attrNames anims)}";
assert lib.assertMsg (lib.lists.all validParts (
  lib.attrValues anims
)) "plymouth-theme-custom: an animation set needs loop and may only have intro";
assert lib.assertMsg (
  isColor background && isColor text
) "plymouth-theme-custom: colors must be #rrggbb, got background ${background} and text ${text}";

stdenvNoCC.mkDerivation {
  pname = "plymouth-theme-custom";
  version = "1.0.0";

  dontUnpack = true;

  nativeBuildInputs = [ ffmpeg-headless ];

  dontBuild = true;

  installPhase =
    let
      themeDir = "$out/share/plymouth/themes/${name}";
    in
    ''
      runHook preInstall

      mkdir -p ${themeDir}
      cp ${catDir}/{box,bullet,entry,lock}.png ${themeDir}

      frames() {
        if [ -d "$1" ]; then
          i=0
          find "$1" -maxdepth 1 -name '*.png' | sort -V | while read -r frame; do
            ffmpeg -nostdin -loglevel error -i "$frame" -vf "null${scale}" "${themeDir}/$2-$i.png"
            i=$((i + 1))
          done
        else
          ffmpeg -nostdin -loglevel error -i "$1" -vf "fps=${toString fps}${scale}" -start_number 0 "${themeDir}/$2-%d.png"
        fi
        count=$(find ${themeDir} -name "$2-*.png" | wc -l)
        if [ "$count" -eq 0 ]; then
          echo "no frames in $1" >&2
          exit 1
        fi
        echo "frames[\"$2\"] = $count;" >> header
      }

      echo "fps = ${toString fps};" > header
      ${lib.strings.concatLines frames}

      cat header - ${./theme.script} > ${themeDir}/${name}.script <<'EOF'
      ${rgb "background" background}${rgb "text" text}
      EOF

      cat > ${themeDir}/${name}.plymouth <<EOF
      [Plymouth Theme]
      Name=${name}
      Description=Plays an animation while booting
      ModuleName=script

      [script]
      ImageDir=${themeDir}
      ScriptFile=${themeDir}/${name}.script
      EOF

      runHook postInstall
    '';

  meta = {
    description = "Plymouth theme that plays a video, gif or png frames per boot mode";
    inherit (plymouth-theme-cat.meta) license;
    platforms = lib.platforms.linux;
  };
}
