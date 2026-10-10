#!/bin/bash
# 3つのパッケージ(Domain / DataLayer / Features)のテストをまとめて動かす。1つでも失敗したら終了コードは 1。
#
# Usage: scripts/test.sh [シミュレーターの名前または UDID]   (省略すると iPhone 18 Pro)
set -uo pipefail
cd "$(dirname "$0")/.."

DEVICE="${1:-iPhone 18 Pro}"
if [[ "$DEVICE" =~ ^[0-9A-F-]{36}$ ]]; then
  DESTINATION="id=$DEVICE"
else
  DESTINATION="platform=iOS Simulator,name=$DEVICE"
fi

failed=()
for package in Domain DataLayer Features; do
  echo "== $package"
  # プロダクトが複数あるパッケージのスキームは「<名前>-Package」、1つだけなら「<名前>」になる。
  scheme="$package-Package"
  (cd "App/$package" && xcodebuild -list 2>/dev/null) | grep -qx "[[:space:]]*$scheme" || scheme="$package"
  (cd "App/$package" && xcodebuild test -scheme "$scheme" -destination "$DESTINATION" -skipPackagePluginValidation 2>&1) \
    | grep -E "error:|Test run with|\*\* TEST"
  [ "${PIPESTATUS[0]}" -eq 0 ] || failed+=("$package")
done

if [ ${#failed[@]} -gt 0 ]; then
  echo "失敗: ${failed[*]}"
  exit 1
fi
echo "すべて成功"
