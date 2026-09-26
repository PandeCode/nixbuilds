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

  tools = with pkgs; {
    # keep-sorted start block=yes newline_separated=yes
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
      typescript-language-server
      vscode-langservers-extracted
    ];

    zig = [
      zig
      zls
    ];
    # keep-sorted end
  };

  minimal = concatLists (
    with tools;
    [
      base
      fennel
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
    fun = minimal ++ tools.fun ++ debug;
    go = minimal ++ tools.go ++ debug;
    python = minimal ++ tools.python;
    rust = minimal ++ tools.rust ++ debug;
    web = minimal ++ tools.web;
    zig = minimal ++ tools.zig ++ debug;
    # keep-sorted end

    full = unique (concatLists (builtins.attrValues tools) ++ debug);
  };
}
