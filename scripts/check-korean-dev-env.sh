#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

required_commands=(git xcodebuild swift)
for command_name in "${required_commands[@]}"; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
        echo "missing required command: $command_name" >&2
        exit 1
    fi
done

if [[ ! -d Dictus.xcodeproj ]]; then
    echo "Dictus.xcodeproj was not found in $repo_root" >&2
    exit 1
fi

echo "repository: $repo_root"
echo "branch: $(git branch --show-current)"
echo "xcode: $(xcodebuild -version | tr '\n' ' ')"
echo "swift: $(swift --version | head -1)"
echo "remotes:"
git remote -v

upstream_url="$(git remote get-url upstream 2>/dev/null || true)"
if [[ "$upstream_url" != "https://github.com/getdictus/dictus-ios.git" ]]; then
    echo "warning: upstream does not point to getdictus/dictus-ios" >&2
fi

if ! rg -q 'RequestsOpenAccess' DictusKeyboard/Info.plist; then
    echo "missing RequestsOpenAccess in DictusKeyboard/Info.plist" >&2
    exit 1
fi

if ! rg -q 'group\.solutions\.pivi\.dictus' DictusCore/Sources/DictusCore/AppGroup.swift; then
    echo "App Group identifier was not found where expected" >&2
    exit 1
fi

echo "environment check passed"
