#!/bin/sh
set -eu

# Installs Common Tools apps from their latest releases.
#
#   curl -fsSL https://oddurs.github.io/common-tools/install.sh | sh -s -- stats bar
#
# For each app it downloads the latest release's zip, checks it against the published .sha256,
# removes the quarantine flag (the builds are signed but not notarized, so macOS would otherwise ask
# you to allow the app in Privacy & Security first), moves the app into /Applications in place of an
# older copy after quitting it, and opens it. With no arguments it lists the apps; `all` installs
# every released one. Run it again any time: it installs whatever the latest release is.
#
# COMMON_TOOLS_DIR installs somewhere other than /Applications. GITHUB_TOKEN, if set, is sent to the
# GitHub API, which helps only when the unauthenticated limit of 60 requests an hour is used up.

monorepo="oddurs/common-tools"
site="https://oddurs.github.io/common-tools"
dir="${COMMON_TOOLS_DIR:-/Applications}"

# slug | name | release asset | repository the app was released from before the monorepo | permission
apps='stats|Common Stats|CommonStats|common-stats|
keys|Common Keys|CommonKeys|common-keys|Accessibility
bar|Common Bar|CommonBar|common-bar|'

die() {
    echo "install: $*" >&2
    exit 1
}

list() {
    echo "Common Tools: small, native utilities for the Mac. $site"
    echo
    echo "$apps" | while IFS='|' read -r slug name _ _ _; do printf '  %-6s %s\n' "$slug" "$name"; done
    echo
    echo "usage: curl -fsSL $site/install.sh | sh -s -- <app> [<app> ...]"
    echo "       curl -fsSL $site/install.sh | sh -s -- all"
}

row() { echo "$apps" | grep "^$1|" || die "no app '$1'; run with no arguments to list them"; }

api() {
    # Fetches a GitHub API path, with a token only when the environment already has one.
    if [ -n "${GITHUB_TOKEN:-}" ]; then
        curl -fsSL -H "Accept: application/vnd.github+json" -H "Authorization: Bearer $GITHUB_TOKEN" "$@"
    else
        curl -fsSL -H "Accept: application/vnd.github+json" "$@"
    fi
}

# Prints the base URL of the app's latest release assets: the monorepo's newest <slug>-v* tag, or
# the old repository's latest release before the first one here, the same order the site uses.
release_base() {
    slug="$1" legacy="$2"
    api -o "$tmp/releases.json" "https://api.github.com/repos/$monorepo/releases?per_page=100" ||
        die "can't read $monorepo's releases from api.github.com"
    tag="$(grep -o "\"tag_name\": *\"$slug-v[^\"]*\"" "$tmp/releases.json" | head -n 1 | sed 's/.*"\(.*\)"/\1/')"
    if [ -n "$tag" ]; then
        echo "https://github.com/$monorepo/releases/download/$tag"
        return
    fi
    [ -n "$legacy" ] || die "$slug has no release yet"
    # /releases/latest redirects to /releases/tag/<tag>; no redirect means no release.
    page="$(curl -fsSI -o /dev/null -w '%{redirect_url}' "https://github.com/oddurs/$legacy/releases/latest")" ||
        die "can't reach github.com/oddurs/$legacy"
    tag="${page##*/}"
    [ -n "$tag" ] && [ "$tag" != latest ] || die "$slug has no release yet"
    echo "https://github.com/oddurs/$legacy/releases/download/$tag"
}

# Quits the running copy of a bundle, politely first, so its settings are saved before it's replaced.
quit() {
    bundle_id="$1" executable="$2"
    pgrep -xq "$executable" || return 0
    osascript -e "tell application id \"$bundle_id\" to quit" >/dev/null 2>&1 || :
    i=0
    while pgrep -xq "$executable"; do
        i=$((i + 1))
        [ "$i" -lt 50 ] || { pkill -x "$executable"; sleep 1; break; }
        sleep 0.2
    done
    pgrep -xq "$executable" && die "couldn't quit $executable"
    return 0
}

install() {
    IFS='|' read -r slug name asset legacy permission <<EOF
$(row "$1")
EOF
    base="$(release_base "$slug" "$legacy")"
    version="${base##*/v}"
    echo "==> $name $version"
    work="$tmp/$slug"
    mkdir -p "$work"
    curl -fsSL -o "$work/$asset.zip" "$base/$asset.zip" || die "can't download $base/$asset.zip"
    curl -fsSL -o "$work/$asset.zip.sha256" "$base/$asset.zip.sha256" || die "can't download $base/$asset.zip.sha256"
    (cd "$work" && shasum -a 256 --status -c "$asset.zip.sha256") || die "$asset.zip doesn't match its published checksum"
    ditto -x -k "$work/$asset.zip" "$work/unzipped"
    app="$(find "$work/unzipped" -maxdepth 1 -name '*.app' | head -n 1)"
    [ -n "$app" ] || die "$asset.zip holds no app"
    plist="$app/Contents/Info.plist"
    bundle_id="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$plist")"
    executable="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$plist")"
    # The zip was made from a signed bundle and curl sets no quarantine flag, so there's normally
    # nothing to remove; a browser download opened the same way would have one.
    xattr -dr com.apple.quarantine "$app" 2>/dev/null || :
    target="$dir/$(basename "$app")"
    # The copy being replaced may carry an identity the app had before a rename; quit it by its own.
    if [ -e "$target/Contents/Info.plist" ]; then
        quit "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$target/Contents/Info.plist")" \
            "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$target/Contents/Info.plist")"
    fi
    quit "$bundle_id" "$executable"
    if [ -e "$target" ]; then
        echo "    replacing $target"
        rm -rf "$target" || die "can't remove $target"
    fi
    mv "$app" "$target" || die "can't move $name into $dir"
    open "$target" || die "installed, but couldn't open $target"
    echo "    installed and opened $target"
    [ -z "$permission" ] || echo "    needs $permission: System Settings › Privacy & Security › $permission; it asks on first run"
}

[ "$(uname)" = Darwin ] || die "Common Tools apps are for macOS"
[ $# -gt 0 ] || { list; exit 0; }
[ -d "$dir" ] || die "$dir doesn't exist; set COMMON_TOOLS_DIR to a folder that does"
[ -w "$dir" ] || die "$dir isn't writable; log in as an administrator or set COMMON_TOOLS_DIR"
for tool in curl shasum ditto xattr osascript; do
    command -v "$tool" >/dev/null || die "needs $tool"
done

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

if [ "$*" = all ]; then
    # shellcheck disable=SC2046
    set -- $(echo "$apps" | cut -d'|' -f1)
fi
# Check every name before touching anything, so a typo in the second app doesn't half-install.
for slug in "$@"; do row "$slug" >/dev/null; done
for slug in "$@"; do install "$slug"; done
