{
  lib,
  stdenv,
  autoPatchelfHook,
  fetchFromGitHub,
  fetchPypi,
  unzip,
}:

# building the compiler means building iree's llvm fork, hours on ci. the
# release wheel ships the same libIREECompiler.so and tools, so this takes
# those and patches them for nixos. iree-runtime is built from source
let
  platforms = {
    x86_64-linux = {
      platform = "manylinux_2_27_x86_64.manylinux_2_28_x86_64";
      hash = "sha256-0J0uvYlV0+7qtWdwB8PSaDDIWFxhoODM38AgtjwSnm8=";
    };
    aarch64-linux = {
      platform = "manylinux_2_27_aarch64.manylinux_2_28_aarch64";
      hash = "sha256-Iwrsm11jxJ8/G6Iow1p86VAHXOe3eAt4bIX6b7C+Pbs=";
    };
  };
in

stdenv.mkDerivation (finalAttrs: {
  pname = "iree-compiler";
  version = "3.13.0";

  src = fetchPypi {
    pname = "iree_base_compiler";
    inherit (finalAttrs) version;
    format = "wheel";
    dist = "cp312";
    python = "cp312";
    abi = "abi3";
    inherit (platforms.${stdenv.hostPlatform.system}) platform hash;
  };

  nativeBuildInputs = [
    autoPatchelfHook
    unzip
  ];

  buildInputs = [ stdenv.cc.cc.lib ];

  unpackPhase = ''
    runHook preUnpack
    unzip -q $src 'iree/compiler/_mlir_libs/*'
    runHook postUnpack
  '';

  # the tools find libIREECompiler.so through their runpath, and it finds
  # iree-lld in ../bin. the python modules are left out, they need the
  # python package around them
  installPhase = ''
    runHook preInstall
    cd iree/compiler/_mlir_libs
    install -Dm755 iree-compile iree-link iree-lld iree-opt -t $out/bin
    install -Dm755 libIREECompiler.so -t $out/lib
    mkdir -p $out/lib/iree_platform_libs
    cp -r iree_platform_libs/rocm $out/lib/iree_platform_libs
    # the C API to embed the compiler. mlir_interop.h is left out, it needs
    # mlir's own headers
    cd ${finalAttrs.passthru.source}/compiler/bindings/c/iree/compiler
    install -Dm444 api_support.h embedding_api.h loader.h tool_entry_points_api.h \
      -t $out/include/iree/compiler
    runHook postInstall
  '';

  # the source at the same tag, for the headers the wheel does not have.
  # iree-runtime builds from it too
  passthru.source = fetchFromGitHub {
    owner = "iree-org";
    repo = "iree";
    tag = "v${finalAttrs.version}";
    hash = "sha256-BnImem/CKSYKRZ9JIyq+VRGkYeCnHJEjcutGI4DevLY=";
  };

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    $out/bin/iree-compile --version
    runHook postInstallCheck
  '';

  meta = {
    description = "IREE MLIR compiler: StableHLO, TOSA and Torch to CPU, Vulkan, ROCm and CUDA";
    homepage = "https://iree.dev";
    changelog = "https://github.com/iree-org/iree/releases/tag/v${finalAttrs.version}";
    license = with lib.licenses; [
      asl20
      llvm-exception
    ];
    mainProgram = "iree-compile";
    platforms = lib.attrNames platforms;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
