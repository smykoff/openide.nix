#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

base=https://download.openide.ru
latest=$(curl -fsSL https://openide.ru/download/other \
  | grep -oP 'openIDE-\K[0-9.]+(?=\.tar\.gz)' | sort -uV | tail -n1)
current=$(jq -r .version sources.json 2>/dev/null || echo none)

if [ "$latest" = "$current" ]; then
  echo "up to date: $current"; exit 0
fi

declare -A files=(
  [x86_64-linux]="openIDE-$latest.tar.gz"
  [aarch64-linux]="openIDE-$latest-aarch64.tar.gz"
  [aarch64-darwin]="openIDE-$latest-aarch64.dmg"
)

json=$(jq -n --arg v "$latest" '{version: $v}')
for sys in "${!files[@]}"; do
  url="$base/$latest/${files[$sys]}"
  hash=$(nix store prefetch-file --json "$url" | jq -r .hash)
  json=$(jq --arg s "$sys" --arg u "$url" --arg h "$hash" \
    '.[$s] = {url: $u, hash: $h}' <<<"$json")
done

jq . <<<"$json" > sources.json
echo "updated: $current -> $latest"
echo "version=$latest" >> "${GITHUB_OUTPUT:-/dev/null}"
