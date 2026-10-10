#!/bin/bash
# 実機用(Development 署名)の ipa を作り、Tailscale 経由の OTA インストールリンクで配る。
# iPhone で表示されるリンクを開き、「インストール」を1回タップすると入る。
#
# 前提: iPhone の UDID が開発チームに登録済み / Mac で Tailscale が起動している
# 使い方: scripts/ota.sh [--no-serve]
set -euo pipefail
cd "$(dirname "$0")/.."

BUNDLE_ID=com.akidon0000.tabimemo
SCHEME=TabiMemo
OUT="$PWD/build/ota"
URL_PATH=/tabimemo
PORT=8099

rm -rf build/ota-export "$OUT"
mkdir -p "$OUT"

xcodebuild archive -project App/TabiMemo.xcodeproj -scheme "$SCHEME" -configuration Release \
  -destination 'generic/platform=iOS' -archivePath "build/$SCHEME-dev.xcarchive" \
  -allowProvisioningUpdates -skipPackagePluginValidation
xcodebuild -exportArchive -archivePath "build/$SCHEME-dev.xcarchive" \
  -exportOptionsPlist scripts/ExportOptions-dev.plist -exportPath build/ota-export \
  -allowProvisioningUpdates
cp build/ota-export/"$SCHEME".ipa "$OUT/$SCHEME.ipa"

HOST=$(tailscale status --json | python3 -c 'import json,sys; print(json.load(sys.stdin)["Self"]["DNSName"].rstrip("."))')
BASE="https://$HOST$URL_PATH"
VERSION=$(/usr/libexec/PlistBuddy -c 'Print :ApplicationProperties:CFBundleShortVersionString' "build/$SCHEME-dev.xcarchive/Info.plist")

cat > "$OUT/manifest.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict><key>items</key><array><dict>
<key>assets</key><array><dict><key>kind</key><string>software-package</string><key>url</key><string>$BASE/$SCHEME.ipa</string></dict></array>
<key>metadata</key><dict><key>bundle-identifier</key><string>$BUNDLE_ID</string><key>bundle-version</key><string>$VERSION</string><key>kind</key><string>software</string><key>title</key><string>TabiMemo</string></dict>
</dict></array></dict></plist>
PLIST

# ビルドの記録(build/ota-history.json)に今回分を足し、index.html を作る。履歴は ota.sh を消さない限り残る
BUILD=$(/usr/libexec/PlistBuddy -c 'Print :ApplicationProperties:CFBundleVersion' "build/$SCHEME-dev.xcarchive/Info.plist")
COMMIT=$(git rev-parse --short HEAD)$(git diff --quiet HEAD -- . ':!build' || echo "+未コミットの変更あり")
SUBJECT=$(git log -1 --format=%s)
python3 - "$OUT/index.html" "$BASE" "$VERSION" "$BUILD" "$COMMIT" "$SUBJECT" <<'PY'
import datetime, html, json, os, sys
out, base, version, build, commit, subject = sys.argv[1:]
hist_path = "build/ota-history.json"
hist = json.load(open(hist_path)) if os.path.exists(hist_path) else []
jst = datetime.timezone(datetime.timedelta(hours=9))
now = datetime.datetime.now(jst)
hist.append({"time": now.isoformat(timespec="seconds"), "version": version, "build": build, "commit": commit, "subject": subject})
hist = hist[-10:]
json.dump(hist, open(hist_path, "w"), ensure_ascii=False, indent=1)

def fmt(e):
    return datetime.datetime.fromisoformat(e["time"]).strftime("%Y-%m-%d %H:%M")
def row(e):
    return "<tr><td>%s</td><td>%s (%s)</td><td>%s</td><td>%s</td></tr>" % (
        fmt(e), html.escape(e["version"]), html.escape(e["build"]), html.escape(e["commit"]), html.escape(e["subject"]))
prev = hist[-2] if len(hist) > 1 else None
link = "itms-services://?action=download-manifest&url=" + base + "/manifest.plist"
page = f"""<!doctype html><meta charset="utf-8"><meta name="viewport" content="width=device-width">
<title>TabiMemo</title>
<style>body{{font-family:-apple-system,sans-serif;margin:16px}}td,th{{padding:4px 8px;text-align:left;font-size:13px}}</style>
<p><a href="{link}" style="font-size:1.6em">TabiMemo をインストール</a></p>
<p>ipa 作成: <b>{fmt(hist[-1])}</b>(v{html.escape(version)} / build {html.escape(build)})<br>
コミット: {html.escape(commit)} {html.escape(subject)}<br>
前回: {("<b>" + fmt(prev) + "</b>(" + html.escape(prev["commit"]) + ")") if prev else "なし"}</p>
<h4>履歴(新しい順)</h4>
<table><tr><th>作成</th><th>版</th><th>コミット</th><th>内容</th></tr>{"".join(row(e) for e in reversed(hist))}</table>
<script>location.href = {json.dumps(link)}</script>
"""
open(out, "w").write(page)
PY

if [[ "${1:-}" != --no-serve ]]; then
  # macOS 版 Tailscale は serve でフォルダを直接配れないので、簡易サーバー経由のプロキシにする
  lsof -ti tcp:$PORT -sTCP:LISTEN | xargs kill 2>/dev/null || true
  (cd "$OUT" && nohup python3 -m http.server $PORT --bind 127.0.0.1 >/dev/null 2>&1 </dev/null &)
  tailscale serve --bg --set-path "$URL_PATH" "http://127.0.0.1:$PORT"
fi
echo "iPhone で開く: $BASE/"
