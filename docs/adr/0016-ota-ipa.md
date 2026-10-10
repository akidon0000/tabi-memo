# 0016: 開発中の実機確認は、Tailscale 経由の OTA で ipa を配る

- 状態: 有効
- 読み手: 将来の自分・エージェント
- 日付: 2026-10-11

## 決定

Mac から離れた場所で開発するとき、実機への配信は TestFlight ではなく、Development 署名の ipa を Tailscale 経由で配る OTA インストールにする(`scripts/ota.sh`)。TestFlight は節目の確認と他の人への配信に使う([release.md](../handbook/release.md))。

## 背景

TestFlight はアップロード後の処理に10分前後かかり、直して試すを繰り返す開発には遅い。ipa ならビルドが終われば数秒で入れられる。

## 比較

| 案 | 採否 |
|---|---|
| A. `devicectl` で Mac から直接入れる(フォルダ監視) | 不採用。iPhone が Mac と同じ LAN か USB にいる必要があり、Tailscale 越しの接続は未検証 |
| B. Tailscale で ipa と manifest.plist を配る OTA | 採用 |
| C. TestFlight のまま | 開発中は不採用。節目の確認には使い続ける |

## 決めたこと・割り切り

- iPhone で `itms-services` のリンクを開いたあと「インストール」を1回タップする。完全に自動では入らない(iOS の制約)。
- 署名は Development(`scripts/ExportOptions-dev.plist`、自動署名)。iPhone の UDID が開発チームに登録されている必要がある。
- macOS 版の Tailscale は `tailscale serve` でフォルダを直接配れない(path serving 非対応)。`python3 -m http.server`(127.0.0.1:8099)を立て、`/tabimemo` をそこへプロキシする。既存の `/`(8080)には触れない。
- 配信先は tailnet 内だけ(`tailnet only`)。iPhone 側で Tailscale が接続している必要がある。
- `build/` は git に入れない。ipa・manifest・ビルド履歴(`build/ota-history.json`)はマシンごとに作り直す。別のマシンで使うための準備と手順は [release.md](../handbook/release.md) の「開発中の実機確認(OTA)」に書いた(コードに残るのは `scripts/ota.sh` と `scripts/ExportOptions-dev.plist` だけで、Apple ID・UDID・ts.net 名は含めない。ts.net 名は実行時に `tailscale status` から取る)。
