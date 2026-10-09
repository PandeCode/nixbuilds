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

# chromium extensions: whatever file the store serves now, with the version
# from its own manifest. chromium's version comes from this flake's nixpkgs,
# after `nix flake update`, so it is the one these get built for
chromium_extensions() {
    local file=pkgs/by-name/chromium-extensions/extensions.nix
    local chrome json name e id repo version url out hash old bad=0
    chrome=$(nix eval --raw .#legacyPackages.x86_64-linux.ungoogled-chromium.version) || return 1
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
            + (.value as $v | ["id", "version", "hash", "github", "asset"]
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
