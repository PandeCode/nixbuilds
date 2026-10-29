# language tools shared by my editors (hermes, libys), so both install the
# same versions
{ pkgs }:

let
  inherit (pkgs) lib;
  inherit (lib.lists) concatLists unique;

  debug = with pkgs; [
    gdb
    lldb
    vscode-extensions.vadimcn.vscode-lldb
  ];

  # agda with the standard library, als embeds its own agda and gets the same
  # libraries through AGDA_DIR
  agdaWithLibraries = pkgs.agda.withPackages (p: [ p.standard-library ]);
  alsWithLibraries = pkgs.symlinkJoin {
    name = "als-with-libraries";
    paths = [ pkgs.agda-language-server ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = "wrapProgram $out/bin/als --set-default AGDA_DIR ${agdaWithLibraries.agdaDir}";
  };

  tools = with pkgs; {
    # keep-sorted start block=yes newline_separated=yes
    agda = [
      agdaWithLibraries
      alsWithLibraries
    ];

    base = [
      ast-grep
      fd
      harper
      proselint
      ripgrep
      universal-ctags
    ];

    cxx = [
      asm-lsp
      ccls
      clang-tools
      cmake-format
      cmake-lint
      neocmakelsp
    ];

    fennel = [
      fennel-ls
      fnlfmt
      luaPackages.fennel
    ];

    fun = [
      cabal-install
      ghc
      haskell-language-server
      matlab-language-server
      ocaml
      ocamlPackages.ocaml-lsp
      sbcl
      stack
    ];

    go = [
      go
      go-tools
      gopls
      gotools
    ];

    janet = [
      janet
      janet-lsp
    ];

    lua = [
      emmylua-check
      emmylua-doc-cli
      emmylua-ls
      stylua
    ];

    nix = [
      alejandra
      deadnix
      nixd
      nixfmt
      statix
    ];

    python = [
      basedpyright
      black
      pyrefly
      ruff
    ];

    rust = [
      cargo
      rust-analyzer
      rustc
    ];

    shell = [
      bash-language-server
      shfmt
    ];

    web = [
      emmet-ls
      eslint
      mermaid-cli
      tailwindcss-language-server
      # typescript-language-server
      vscode-langservers-extracted
    ];

    zig = [
      zig_0_17
      zls-master
    ];
    # keep-sorted end
  };

  minimal = concatLists (
    with tools;
    [
      base
      fennel
      janet
      lua
      nix
      shell
    ]
  );
in

tools
// {
  inherit debug;

  profiles = {
    inherit minimal;

    # keep-sorted start
    cxx = minimal ++ tools.cxx ++ debug;
    fun = minimal ++ tools.agda ++ tools.fun ++ debug;
    go = minimal ++ tools.go ++ debug;
    python = minimal ++ tools.python;
    rust = minimal ++ tools.rust ++ debug;
    web = minimal ++ tools.web;
    zig = minimal ++ tools.zig ++ debug;
    # keep-sorted end

    full = unique (concatLists (builtins.attrValues tools) ++ debug);
  };
}
