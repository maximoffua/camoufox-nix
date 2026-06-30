repo="daijro/camoufox"

# Path relative to the repo root; run this from there.
target="${CAMOUFOX_BIN_VERSIONS:-packages/camoufox-bin/versions.json}"
if [ ! -f "$target" ]; then
  echo "camoufox-bin-update: $target not found (run from the repo root)" >&2
  exit 1
fi

# No tag arg → latest release.
if [ "$#" -gt 0 ]; then
  release="$(gh release view "$1" --repo "$repo" --json tagName,assets)"
else
  release="$(gh release view --repo "$repo" --json tagName,assets)"
fi

tag="$(jq -r '.tagName' <<<"$release")"
display="${tag#v}"
firefox="${display%%-*}"

x86_asset="$(jq -r '.assets[].name | select(endswith("lin.x86_64.zip"))' <<<"$release")"
arm_asset="$(jq -r '.assets[].name | select(endswith("lin.arm64.zip"))' <<<"$release")"
if [ -z "$x86_asset" ] || [ -z "$arm_asset" ]; then
  echo "camoufox-bin-update: could not find both Linux assets in $tag" >&2
  exit 1
fi

# The per-arch version is the asset name minus the fixed prefix/suffix.
x86_version="${x86_asset#camoufox-}"
x86_version="${x86_version%-lin.x86_64.zip}"
arm_version="${arm_asset#camoufox-}"
arm_version="${arm_version%-lin.arm64.zip}"

# Hash an asset without importing it into the store: download to a temp dir,
# unpack, and take the NAR hash fetchzip expects.
sri() {
  local dir hash
  dir="$(mktemp -d)"
  echo "camoufox-bin-update: downloading $1" >&2
  curl -fL --progress-bar -o "$dir/$1" "https://github.com/$repo/releases/download/$tag/$1"
  unzip -q "$dir/$1" -d "$dir/unpacked"
  hash="$(nix hash path --type sha256 --sri "$dir/unpacked")"
  rm -rf "$dir"
  printf '%s\n' "$hash"
}

echo "camoufox-bin-update: $tag (firefox $firefox)" >&2
x86_hash="$(sri "$x86_asset")"
arm_hash="$(sri "$arm_asset")"

# Update in place so any other fields are left untouched.
updated="$(jq \
  --arg release "$tag" \
  --arg x86Version "$x86_version" --arg x86Hash "$x86_hash" \
  --arg armVersion "$arm_version" --arg armHash "$arm_hash" \
  '.release = $release
   | .sources."x86_64-linux" = { version: $x86Version, hash: $x86Hash }
   | .sources."aarch64-linux" = { version: $armVersion, hash: $armHash }' \
  "$target")"
printf '%s\n' "$updated" > "$target"

echo "camoufox-bin-update: wrote $target" >&2
