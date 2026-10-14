#!/bin/bash
# 近くにある(USB かワイヤレスでつながっている)iPhone に、ビルドして直接入れて起動する。
#
# Usage: scripts/device.sh [iPhone の名前または UDID]   (省略すると、つながっている iPhone が1台ならそれ)
set -euo pipefail
cd "$(dirname "$0")/.."

BUNDLE_ID=com.akidon0000.tabimemo
WANT="${1:-}"

# 実機(Simulator でない)で、つながっているものだけ。 "available" はペア済みで届く状態。
LIST=$(xcrun devicectl list devices 2>/dev/null | grep -E "iPhone" | grep -v simulated | grep -E " (connected|available)" | grep -v unavailable || true)
if [ -n "$WANT" ]; then
  LIST=$(echo "$LIST" | grep -F "$WANT" || true)
fi
COUNT=$(echo -n "$LIST" | grep -c . || true)
if [ "$COUNT" -eq 0 ]; then
  echo "つながっている iPhone が見つかりません。ロック解除して近づける(または USB でつなぐ)。"
  echo "ワイヤレスで使うには、Mac と同じ Wi-Fi でロック解除し、一度 USB でつないで信頼済みにする(iOS 17 以降は設定のチェックは無い)。"
  exit 1
elif [ "$COUNT" -gt 1 ]; then
  echo "複数見つかりました。名前か UDID を引数で指定してください:"
  echo "$LIST"
  exit 1
fi
UDID=$(echo "$LIST" | grep -oE '[0-9A-F]{8}-[0-9A-F]{16}|[0-9A-F]{8}-([0-9A-F]{4}-){3}[0-9A-F]{12}' | head -1)
echo "== 対象: $LIST"

echo "== ビルド"
(cd App && xcodebuild -scheme TabiMemo -configuration Debug -destination "id=$UDID" \
  -skipPackagePluginValidation -allowProvisioningUpdates build 2>&1 | grep -E "error:|warning: .*signing|\*\* BUILD")

APP=$(ls -td ~/Library/Developer/Xcode/DerivedData/TabiMemo-*/Build/Products/Debug-iphoneos/TabiMemo.app | head -1)
echo "== インストール"
xcrun devicectl device install app --device "$UDID" "$APP"
echo "== 起動(iPhone がロック中だと失敗する。解除して再実行)"
xcrun devicectl device process launch --device "$UDID" --terminate-existing "$BUNDLE_ID"
