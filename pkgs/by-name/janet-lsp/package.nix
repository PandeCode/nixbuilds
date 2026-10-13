{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  janet,
}:

let
  # its lockfile.jdn pins these; bump them with it. all plain janet, so they
  # only need to be on the module path, no jpm
  deps = {
    spork = fetchFromGitHub {
      owner = "janet-lang";
      repo = "spork";
      rev = "dbfc90d4c86fa54a74c56d406517605e49569a8b";
      hash = "sha256-NbQ7Ghu1VINlkMAzQfVUQRtLQ3sUOYjMnrfFV2H1ZNo=";
    };
    cmd = fetchFromGitHub {
      owner = "cfiggers";
      repo = "cmd";
      rev = "b0a34d6e854578bd672d43303e80b9777af08b42";
      hash = "sha256-Kkwde3hHgbi8aj9ud6rOh13KWVxdNCNY4zXnDVj7uzA=";
    };
    judge = fetchFromGitHub {
      owner = "cfiggers";
      repo = "judge";
      rev = "1d329cb3a7384c3ff0f6232e60d81aa9db3a5440";
      hash = "sha256-iR7bCEVvJK3lF9m4hXJhQ4JRnhvcGjgBrWuWIiYT7dg=";
    };
  };
in

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "janet-lsp";
  version = "0.0.13";

  src = fetchFromGitHub {
    owner = "CFiggers";
    repo = "janet-lsp";
    tag = "v${finalAttrs.version}";
    hash = "sha256-lJzTQmjQyyWq+HYEInJuPdcxUwz+KybI5jl0pj9jtIs=";
  };

  # it asks git for its commit at startup, which only works in its own checkout
  postPatch = ''
    sed -i '/^(def commit$/,/^      (if out /c (def commit "v${finalAttrs.version}")' src/main.janet
  '';

  installPhase = ''
    runHook preInstall

    lib=$out/lib/janet
    mkdir -p $lib/spork $lib/cmd $lib/judge $lib/janet-lsp $out/bin
    cp ${deps.spork}/spork/*.janet $lib/spork/
    cp ${deps.cmd}/src/*.janet $lib/cmd/
    cp ${deps.judge}/src/*.janet $lib/judge/
    cp -r src libs $lib/janet-lsp/

    cat >$out/bin/janet-lsp <<EOF
    #!${lib.meta.getExe janet}
    (array/insert module/paths 0 ["$lib/:all:/init.janet" :source])
    (array/insert module/paths 0 ["$lib/:all:.janet" :source])
    (import janet-lsp/src/main :as lsp)
    (defn main [& args] (lsp/main ;args))
    EOF
    chmod +x $out/bin/janet-lsp

    runHook postInstall
  '';

  meta = {
    description = "Language server for Janet";
    homepage = "https://github.com/CFiggers/janet-lsp";
    license = lib.licenses.mit;
    mainProgram = "janet-lsp";
    platforms = janet.meta.platforms;
  };
})
