{
  lib,
  fetchFromGitHub,
  libxcursor,
  libxi,
  libxinerama,
  libxrandr,
  materialx,
}:

# nixpkgs materialx with the viewer and the graph editor on. its own name, so
# blender and openusd keep the cached materialx. the version is pinned here,
# since the submodule hash only holds for this tag
materialx.overrideAttrs (
  finalAttrs: prev: {
    pname = "materialx-tools";
    version = "1.39.5";

    # NanoGUI, ImGui and imgui-node-editor come in as submodules
    src = fetchFromGitHub {
      owner = "AcademySoftwareFoundation";
      repo = "MaterialX";
      tag = "v${finalAttrs.version}";
      fetchSubmodules = true;
      hash = "sha256-a08zqLkjBOPO2AADd7H4yDIfyfah65+WFt0DyJcHgGI=";
    };

    # nanogui and the graph editor build their own glfw against these
    buildInputs = prev.buildInputs ++ [
      libxcursor
      libxi
      libxinerama
      libxrandr
    ];

    cmakeFlags = prev.cmakeFlags ++ [
      (lib.cmakeBool "MATERIALX_BUILD_VIEWER" true)
      (lib.cmakeBool "MATERIALX_BUILD_GRAPH_EDITOR" true)
    ];

    meta = prev.meta // {
      description = "MaterialX with its viewer and graph editor";
      mainProgram = "MaterialXView";
      platforms = lib.platforms.linux;
    };
  }
)
