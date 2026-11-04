#!/usr/bin/env bash
# Baixa os plugins de terceiros nos commits do upstream.lock para vendor/.
#
#   ./sync.sh           sincroniza
#   ./sync.sh --update  avança os commits do lock para o último da branch padrão e sincroniza
set -euo pipefail

cd "$(dirname "$0")"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

entries() { grep -vE '^\s*(#|$)' upstream.lock; }

if [[ "${1:-}" == "--update" ]]; then
  entries | while read -r name repo sha path; do
    latest=$(git ls-remote "$repo" HEAD | cut -f1)
    sed -i.bak "s/$sha/$latest/" upstream.lock
  done
  rm -f upstream.lock.bak
fi

mkdir -p vendor
entries | while read -r name repo sha path; do
  echo "  $name @ ${sha:0:7}"
  src="$tmp/$name"
  dest="vendor/$name"

  git init -q "$src"
  if [[ "$path" != "." ]]; then
    git -C "$src" sparse-checkout set "$path"
  fi
  git -C "$src" fetch -q --depth 1 --filter=blob:none "$repo" "$sha"
  git -C "$src" checkout -q FETCH_HEAD
  rm -rf "$src/.git"

  rm -rf "$dest"
  cp -r "$src/$path/." "$dest"

  # Plugins feitos para o Cursor não trazem manifesto do Claude Code.
  if [[ ! -f "$dest/.claude-plugin/plugin.json" ]]; then
    version=$(sed -nE 's/^\s*"version": "(.*)",?$/\1/p' "$dest/.cursor-plugin/plugin.json" | head -1)
    mkdir -p "$dest/.claude-plugin"
    cat > "$dest/.claude-plugin/plugin.json" <<EOF
{
  "name": "$name",
  "version": "$version",
  "description": "Cópia de $repo/tree/$sha/$path",
  "license": "MIT"
}
EOF
  fi
done
