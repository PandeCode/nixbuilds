#!/usr/bin/env bash
# bumps every package that can find its own new version. run it in
# `nix develop`; the update workflow runs it every week. a package that
# fails is reported and skipped, the rest still update
set -uo pipefail
cd "$(dirname "$0")/.." || exit

failed=()
run() {
    echo "== $1"
    local before
    before=$(git diff --name-only -- pkgs)
    if ! "${@:2}"; then
        failed+=("$1")
        # whatever it changed before failing goes back, so the rest still merge
        comm -13 <(echo "$before") <(git diff --name-only -- pkgs) | xargs -r git checkout --
    fi
}

# releases on github
for pkg in helium hyperfluent-grub-theme plymouth-theme-chain vscodium-server; do
    run "$pkg" nix-update --flake "$pkg"
done

# no releases, or fixes land between tags, so the newest commit
for pkg in excalidraw plymouth-simulated-universe plymouth-theme-cat raddebugger rill; do
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

# xtool from its releases, then the newest patch of the swift it runs on. a
# new swift minor waits until xtool's install docs ask for it
xtool() {
    local file=pkgs/by-name/xtool/package.nix old new hash
    old=$(sed -n 's/^  version = "\(.*\)";$/\1/p' "$file")
    new=$(curl -fsSL ${GITHUB_TOKEN:+-H "Authorization: Bearer $GITHUB_TOKEN"} \
        https://api.github.com/repos/xtool-org/xtool/releases/latest | jq -r .tag_name) || return 1
    [[ -n $new && $new != null ]] || return 1
    if [[ $new != "$old" ]]; then
        hash=$(nix store prefetch-file --json \
            "https://github.com/xtool-org/xtool/releases/download/$new/xtool-x86_64.AppImage" |
            jq -r .hash) || return 1
        sed -i -e "s|^  version = \"$old\";|  version = \"$new\";|" \
            -e "/xtool-x86_64.AppImage/,/hash/{s|hash = \"sha256-[^\"]*\";|hash = \"$hash\";|}" "$file"
        echo "xtool: $old -> $new"
    fi

    old=$(sed -n 's/^    version = "\(.*\)";$/\1/p' "$file")
    new=$(curl -fsSL https://www.swift.org/api/v1/install/releases.json |
        jq -r --arg minor "${old%.*}." '[.[].name | select(startswith($minor))] | last') || return 1
    [[ -n $new && $new != null ]] || return 1
    [[ $new == "$old" ]] && return 0
    hash=$(nix store prefetch-file --json \
        "https://download.swift.org/swift-$new-release/ubuntu2404/swift-$new-RELEASE/swift-$new-RELEASE-ubuntu24.04.tar.gz" |
        jq -r .hash) || return 1
    sed -i -e "s|^    version = \"$old\";|    version = \"$new\";|" \
        -e "/download.swift.org/,/hash/{s|hash = \"sha256-[^\"]*\";|hash = \"$hash\";|}" "$file"
    echo "swift for xtool: $old -> $new"
}
run xtool xtool

# iree: the compiler wheel from pypi and the runtime from the same tag, with
# the submodule commits that tag pins
iree() {
    local compiler=pkgs/by-name/iree-compiler/package.nix
    local runtime=pkgs/by-name/iree-runtime/package.nix
    local old new json sys platform sha hash rev name repo
    old=$(sed -n 's/^  version = "\(.*\)";$/\1/p' "$compiler")
    json=$(curl -fsSL https://pypi.org/pypi/iree-base-compiler/json) || return 1
    new=$(jq -r .info.version <<<"$json")
    [[ -n $new && $new != null ]] || return 1
    [[ $new == "$old" ]] && return 0
    json=$(curl -fsSL "https://pypi.org/pypi/iree-base-compiler/$new/json") || return 1
    for sys in x86_64 aarch64; do
        platform="manylinux_2_27_$sys.manylinux_2_28_$sys"
        sha=$(jq -r --arg f "iree_base_compiler-$new-cp312-abi3-$platform.whl" \
            '.urls[] | select(.filename == $f) | .digests.sha256' <<<"$json")
        [[ -n $sha ]] || return 1
        hash=$(nix hash convert --hash-algo sha256 --to sri "$sha") || return 1
        # the hash line right after this platform's line
        sed -i "/platform = \"$platform\";/{n;s|hash = \"sha256-[^\"]*\";|hash = \"$hash\";|}" "$compiler"
    done
    sed -i "s|^  version = \"$old\";|  version = \"$new\";|" "$compiler"

    # the source at that tag, for the headers and the runtime, then the
    # runtime's submodules, each fetch found by its owner
    hash=$(nix flake prefetch --json "github:iree-org/iree/v$new" | jq -r .hash) || return 1
    sed -i "/repo = \"iree\";/,/hash/{s|hash = \"sha256-[^\"]*\";|hash = \"$hash\";|}" "$compiler"
    for name in flatcc:dvidelabs/flatcc vulkan_headers:KhronosGroup/Vulkan-Headers; do
        repo=${name#*:}
        rev=$(curl -fsSL ${GITHUB_TOKEN:+-H "Authorization: Bearer $GITHUB_TOKEN"} \
            "https://api.github.com/repos/iree-org/iree/contents/third_party/${name%%:*}?ref=v$new" |
            jq -r .sha) || return 1
        bump_github "$runtime" "$repo" "$rev" || return 1
    done
    rev=$(curl -fsSL "https://raw.githubusercontent.com/iree-org/iree/v$new/build_tools/third_party/libbacktrace/CMakeLists.txt" |
        sed -n 's/^set(LIBBACKTRACE_VERSION "\(.*\)")$/\1/p') || return 1
    bump_github "$runtime" ianlancetaylor/libbacktrace "$rev" || return 1
    echo "iree: $old -> $new"
}

# points the fetchFromGitHub of owner/repo in a file at rev, with its hash
bump_github() {
    local file=$1 owner=${2%/*} repo=${2#*/} rev=$3 hash
    [[ $rev =~ ^[0-9a-f]{40}$ ]] || return 1
    hash=$(nix flake prefetch --json "github:$owner/$repo/$rev" | jq -r .hash) || return 1
    sed -i "/owner = \"$owner\";/,/hash/{s|rev = \"[^\"]*\";|rev = \"$rev\";|;s|hash = \"sha256-[^\"]*\";|hash = \"$hash\";|}" "$file"
}
run iree iree

# chromium extensions: whatever file the store serves now, with the version
# from its own manifest. chromium's version comes from this flake's nixpkgs,
# after `nix flake update`, so it is the one these get built for
chromium_extensions() {
    local file=pkgs/by-name/chromium-extensions/extensions.nix
    local chrome json name e id repo version url out hash old bad=0
    chrome=$(nix eval --raw --inputs-from . nixpkgs#ungoogled-chromium.version) || return 1
    json=$(nix eval --json --file "$file") || return 1
    for name in $(jq -r 'keys[]' <<<"$json"); do
        e=$(jq -c --arg n "$name" '.[$n]' <<<"$json")
        id=$(jq -r .id <<<"$e")
        old=$(jq -r .version <<<"$e")
        version=
        if repo=$(jq -er .github <<<"$e"); then
            version=$(curl -fsSL ${GITHUB_TOKEN:+-H "Authorization: Bearer $GITHUB_TOKEN"} \
                "https://api.github.com/repos/$repo/releases/latest" | jq -r .tag_name)
            url="https://github.com/$repo/releases/download/$version/$(jq -r .asset <<<"$e")"
            url=${url//@version@/$version}
        else
            url="https://clients2.google.com/service/update2/crx?response=redirect&acceptformat=crx2,crx3&prodversion=${chrome%%.*}&x=id%3D$id%26installsource%3Dondemand%26uc"
        fi
        if ! out=$(nix store prefetch-file --json --name "$id.crx" "$url"); then
            echo "$name: download failed" >&2
            bad=1
            continue
        fi
        hash=$(jq -r .hash <<<"$out")
        # a crx is a zip with a header in front; unzip warns about it
        [[ -n $version ]] ||
            version=$(unzip -p "$(jq -r .storePath <<<"$out")" manifest.json 2>/dev/null | jq -r .version)
        if [[ -z $version || $version == null ]]; then
            echo "$name: no version" >&2
            bad=1
            continue
        fi
        [[ $version != "$old" ]] && echo "$name: $old -> $version"
        json=$(jq --arg n "$name" --arg v "$version" --arg h "$hash" \
            '.[$n].version = $v | .[$n].hash = $h' <<<"$json")
    done
    jq -r '
        to_entries
        | map("  \(.key | @json) = {\n"
            + (.value as $v | ["name", "id", "version", "hash", "github", "asset"]
                | map(select($v[.] != null) | "    \(.) = \($v[.] | @json);")
                | join("\n"))
            + "\n  };")
        | "# chrome web store extensions, and ublock from its releases. pkgs/update.sh\n# rewrites this file\n{\n" + join("\n\n") + "\n}"
    ' <<<"$json" >"$file"
    return "$bad"
}
run chromium-extensions chromium_extensions

if ((${#failed[@]})); then
    echo "failed: ${failed[*]}" >&2
    exit 1
fi
