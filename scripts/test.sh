#!/bin/bash
# 3つのパッケージ(Domain / DataLayer / Features)のテストをまとめて動かす。
#
# Usage: scripts/test.sh [シミュレーターの名前または UDID]   (省略すると iPhone 18 Pro)
set -euo pipefail
cd "$(dirname "$0")/.."

DEVICE="${1:-iPhone 18 Pro}"
if [[ "$DEVICE" =~ ^[0-9A-F-]{36}$ ]]; then
  DESTINATION="id=$DEVICE"
else
  DESTINATION="platform=iOS Simulator,name=$DEVICE"
fi

# プロダクトが複数あるパッケージのスキームは「<名前>-Package」、1つだけなら「<名前>」になる。
for package in Domain DataLayer Features; do
  echo "== $package"
  (cd "$package"
   scheme="$package-Package"
   xcodebuild -list 2>/dev/null | grep -qx "[[:space:]]*$scheme" || scheme="$package"
   xcodebuild test -scheme "$scheme" -destination "$DESTINATION" -skipPackagePluginValidation 2>&1 \
     | grep -E "error:|Test run with|\*\* TEST" || true)
done
