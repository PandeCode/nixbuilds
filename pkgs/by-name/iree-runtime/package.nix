{
  lib,
  stdenv,
  cmake,
  fetchFromGitHub,
  iree-compiler,
  mesa,
  ninja,
  python3,
  runCommand,
  vulkan-loader,
}:

# the C runtime only, without iree's llvm fork: headers, static libraries and
# cmake config to embed it, and the tools that run compiled .vmfb modules.
# HAL drivers: local-sync and local-task for cpu, vulkan for gpu
let
  # submodules the runtime needs, at the commits v3.13.0 pins. the rest of
  # the submodules belong to the compiler (llvm-project is most of them)
  flatcc = fetchFromGitHub {
    owner = "dvidelabs";
    repo = "flatcc";
    rev = "9362cd00f0007d8cbee7bff86e90fb4b6b227ff3";
    hash = "sha256-umZ9TvNYDZtF/mNwQUGuhAGve0kPw7uXkaaQX0EzkBY=";
  };

  vulkan-headers = fetchFromGitHub {
    owner = "KhronosGroup";
    repo = "Vulkan-Headers";
    rev = "df60f0316899460eeaaefa06d2dd7e4e300c1604";
    hash = "sha256-BT4nNHCe8MivRMQUaipcffbtMS4zuHR5KtzV+naW70w=";
  };

  # fetched by cmake otherwise, for stack traces in error statuses
  libbacktrace = fetchFromGitHub {
    owner = "ianlancetaylor";
    repo = "libbacktrace";
    rev = "b9e40069c0b47a722286b94eb5231f7f05c08713";
    hash = "sha256-vi33Bhg2LT5uWN63PHkD8CaOjTXBwZhBwFFhaezJ0e4=";
  };
in

stdenv.mkDerivation (finalAttrs: {
  pname = "iree-runtime";
  # iree has no stable module format across versions, so the runtime and
  # compiler move together
  inherit (iree-compiler) version;
  src = iree-compiler.source;

  postUnpack = ''
    cp -r --no-preserve=mode ${flatcc}/. $sourceRoot/third_party/flatcc
    cp -r --no-preserve=mode ${vulkan-headers}/. $sourceRoot/third_party/vulkan_headers
    # cmake writes its config.h into the source, so it has to be writable
    cp -r --no-preserve=mode ${libbacktrace} $sourceRoot/third_party/libbacktrace
  '';

  # the vulkan driver dlopens libvulkan.so.1 by name, which nixos does not
  # resolve. IREE_HAL_VULKAN_LIBVULKAN_PATH is its last try before that, so
  # with the variable unset it now looks in this vulkan-loader. a program
  # that links the static libraries gets that too, with no runpath of its own
  postPatch = ''
    substituteInPlace runtime/src/iree/hal/drivers/vulkan/util/libvulkan.c \
      --replace-fail 'getenv("IREE_HAL_VULKAN_LIBVULKAN_PATH")' \
        '(getenv("IREE_HAL_VULKAN_LIBVULKAN_PATH") ?: "${lib.getLib vulkan-loader}/lib")'
  '';

  preConfigure = ''
    cmakeFlagsArray+=(-DFETCHCONTENT_SOURCE_DIR_LIBBACKTRACE_SRC=$PWD/third_party/libbacktrace)
  '';

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    ninja
    python3
  ];

  cmakeFlags = [
    (lib.cmakeBool "IREE_BUILD_COMPILER" false)
    (lib.cmakeBool "IREE_BUILD_TESTS" false)
    (lib.cmakeBool "IREE_BUILD_SAMPLES" false)
    (lib.cmakeBool "IREE_BUILD_BENCHMARKS" false)
    (lib.cmakeBool "IREE_BUILD_BINDINGS_TFLITE" false)
    (lib.cmakeBool "IREE_BUILD_BINDINGS_TFLITE_JAVA" false)
    # it asks git whether the submodules are there; there is no .git
    (lib.cmakeBool "IREE_ERROR_ON_MISSING_SUBMODULES" false)
    # warnings from newer compilers than iree's ci are not errors here
    (lib.cmakeBool "IREE_ENABLE_WERROR_FLAG" false)
  ];

  # plain `install` leaves out the headers and libraries, they are their own
  # components. this is the target iree's release tarballs install
  installTargets = [ "iree-install-dist" ];

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    $out/bin/iree-run-module --list_drivers | grep -q vulkan
    runHook postInstallCheck
  '';

  # `nix build .#iree-runtime.tests.<device>`: a dense layer with relu
  # compiled from stablehlo and run on the cpu, and on vulkan through mesa's
  # software driver, so no gpu is needed
  passthru.tests =
    let
      run =
        device: flags: env:
        runCommand "iree-runtime-test-${device}"
          (
            {
              nativeBuildInputs = [
                iree-compiler
                finalAttrs.finalPackage
              ];
            }
            // env
          )
          ''
            cat > mlp.mlir <<'EOF'
            func.func @main(%x: tensor<4x8xf32>, %w: tensor<8x16xf32>, %b: tensor<16xf32>) -> tensor<4x16xf32> {
              %0 = stablehlo.dot_general %x, %w, contracting_dims = [1] x [0] : (tensor<4x8xf32>, tensor<8x16xf32>) -> tensor<4x16xf32>
              %1 = stablehlo.broadcast_in_dim %b, dims = [1] : (tensor<16xf32>) -> tensor<4x16xf32>
              %2 = stablehlo.add %0, %1 : tensor<4x16xf32>
              %z = stablehlo.constant dense<0.0> : tensor<4x16xf32>
              %3 = stablehlo.maximum %2, %z : tensor<4x16xf32>
              return %3 : tensor<4x16xf32>
            }
            EOF
            iree-compile --iree-input-type=stablehlo ${lib.escapeShellArgs flags} mlp.mlir -o mlp.vmfb
            # 8 * 0.5 - 1 = 3 in every element
            iree-run-module --device=${device} --module=mlp.vmfb \
              --input=4x8xf32=1 --input=8x16xf32=0.5 --input=16xf32=-1 | tee $out
            grep -q '^4x16xf32=\[3 3 3' $out
          '';
    in
    {
      local-task = run "local-task" [
        "--iree-hal-target-device=local"
        "--iree-hal-local-target-device-backends=llvm-cpu"
        "--iree-llvmcpu-target-cpu=generic"
      ] { };
      vulkan = run "vulkan" [ "--iree-hal-target-device=vulkan" ] {
        VK_ICD_FILENAMES = "${mesa}/share/vulkan/icd.d/lvp_icd.${stdenv.hostPlatform.uname.processor}.json";
      };
    };

  meta = {
    description = "IREE runtime: C API, HAL drivers (cpu, vulkan) and tools to run compiled modules";
    homepage = "https://iree.dev";
    changelog = "https://github.com/iree-org/iree/releases/tag/v${finalAttrs.version}";
    license = with lib.licenses; [
      asl20
      llvm-exception
    ];
    mainProgram = "iree-run-module";
    platforms = lib.platforms.linux;
  };
})
