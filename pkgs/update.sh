#!/usr/bin/env bash
# bumps every package that can find its own new version. run it in
# `nix develop`; the update workflow runs it every week. a package that
# fails is reported and skipped, the rest still update
set -uo pipefail
cd "$(dirname "$0")/.." || exit

failed=()
run() {
    echo "== $1"
    "${@:2}" || failed+=("$1")
}

# releases on github
for pkg in helium hyperfluent-grub-theme plymouth-theme-chain; do
    run "$pkg" nix-update --flake "$pkg"
done

# no releases, or fixes land between tags, so the newest commit
for pkg in plymouth-simulated-universe plymouth-theme-cat raddebugger rill; do
    run "$pkg" nix-update --flake --version=branch "$pkg"
done

# betterbird only says its version on its download page
betterbird() {
    local file=pkgs/by-name/betterbird-unwrapped/package.nix old new hash
    old=$(sed -n 's/^  version = "\(.*\)";$/\1/p' "$file")
    new=$(curl -fsSL https://www.betterbird.eu/downloads/ |
        grep -o '([0-9.]*esr-bb[0-9]*,' | head -1 | tr -d '(,')
    [[ -n $new ]] || return 1
    [[ $new == "$old" ]] && return 0
    hash=$(nix store prefetch-file --json \
        "https://www.betterbird.eu/downloads/LinuxArchive/betterbird-$new.en-US.linux-x86_64.tar.xz" |
        jq -r .hash) || return 1
    sed -i -e "s|version = \"$old\";|version = \"$new\";|" \
        -e "s|hash = \"sha256-[^\"]*\";|hash = \"$hash\";|" "$file"
    echo "betterbird: $old -> $new"
}
run betterbird betterbird

if ((${#failed[@]})); then
    echo "failed: ${failed[*]}" >&2
    exit 1
fi
