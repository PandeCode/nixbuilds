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
  # how frames fill the screen: none, contain, cover or stretch
  fit ? "none",
  # where the animation and the password box sit, x and y from 0 (left,
  # top) to 1 (right, bottom)
  position ? { },
  promptPosition ? { },
  # images for the password prompt: box, lock, entry, bullet
  promptImages ? { },
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

  fits = [
    "none"
    "contain"
    "cover"
    "stretch"
  ];

  # the default password prompt images and animation come from the cat
  catDir = "${plymouth-theme-cat}/share/plymouth/themes/PlymouthTheme-Cat";

  cat = runCommandLocal "plymouth-cat-frames" { } ''
    mkdir $out
    cp ${catDir}/progress-*.png $out
  '';

  prompt =
    lib.genAttrs [ "box" "lock" "entry" "bullet" ] (part: "${catDir}/${part}.png") // promptImages;

  pos = {
    x = 0.5;
    y = 0.5;
  }
  // position;
  promptPos = {
    x = 0.5;
    y = 0.8;
  }
  // promptPosition;
  isPos =
    p:
    lib.attrNames p == [
      "x"
      "y"
    ]
    && lib.lists.all (v: lib.isFloat v || lib.isInt v) [
      p.x
      p.y
    ]
    && p.x >= 0
    && p.x <= 1
    && p.y >= 0
    && p.y <= 1;

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
assert lib.assertMsg (lib.lists.elem fit fits)
  "plymouth-theme-custom: fit must be one of ${lib.strings.concatStringsSep ", " fits}, got ${fit}";
assert lib.assertMsg (
  isPos pos && isPos promptPos
) "plymouth-theme-custom: position and promptPosition take x and y between 0 and 1";
assert lib.assertMsg (
  lib.attrNames prompt == [
    "box"
    "bullet"
    "entry"
    "lock"
  ]
) "plymouth-theme-custom: promptImages may only set box, lock, entry and bullet";
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
      ${lib.strings.concatLines (
        lib.attrsets.mapAttrsToList (
          part: file:
          "ffmpeg -nostdin -loglevel error -i ${lib.strings.escapeShellArg "${file}"} ${themeDir}/${part}.png"
        ) prompt
      )}

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
      fit = "${fit}";
      position_x = ${toString pos.x};
      position_y = ${toString pos.y};
      prompt_x = ${toString promptPos.x};
      prompt_y = ${toString promptPos.y};
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
