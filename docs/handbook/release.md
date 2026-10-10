# リリース(TestFlight)

- 読み手: このリポジトリで作業する自分・エージェント
- 目的: 実機テスト用に TabiMemo を TestFlight へ配信する現在の手順
- 共通部分(asc の採用理由・認証): [hq の handbook/ios-release.md](https://github.com/akidon0000/hq/blob/main/docs/handbook/ios-release.md)。ここには TabiMemo 固有の値だけ置く。参考にした実装は meguri リポジトリの `docs/handbook/release.md`

## このアプリの値

| 項目 | 値 |
|---|---|
| Bundle ID | `com.akidon0000.tabimemo`(ASC の Bundle ID 登録済み、ID `3DBK34BGQX`) |
| Team ID | `XSC9AJPSP3` |
| App Store Connect App ID | `6818975282`(ASC 上の名前は「旅メモ - tabimemo」。「旅メモ」は他アカウントが使用中で改名できなかった。端末の表示名は影響なし) |
| 署名 | 手動。プロファイル `IOS_APP_STORE-20261004`(期限 2027-05-03) |

## 手順

### 0. アプリレコードを作る(ユーザーが自分で行う。2026-10-04 完了)

`asc web apps create` は Apple ID のパスワードと 2FA が要るので、自分のターミナルで実行する(エージェントは行えない)。

```bash
asc web apps create --name "旅メモ" --bundle-id "com.akidon0000.tabimemo" \
  --sku "tabimemo-ios" --primary-locale "ja"
asc apps list    # App ID(数値)を控える
```

名前が既に使われていると、自動で別名になる(meguri がそうだった)。その場合は `asc apps rename` で直す。

### 1. 署名の準備(完了済み。プロファイルが切れたとき・別のマシンで行う)

```bash
asc signing fetch --bundle-id com.akidon0000.tabimemo --profile-type IOS_APP_STORE \
  --create-missing --output ./signing
asc profiles local install --path signing/IOS_APP_STORE-*.mobileprovision --force
```

新しいプロファイル名になったら `scripts/ExportOptions.plist` の `provisioningProfiles` を合わせる。`signing/` は git に入れない。

### 2. アップロード

```bash
scripts/testflight.sh <APP_ID>                              # アップロードのみ
scripts/testflight.sh <APP_ID> --group "Internal" --notify  # 内部テスターへ配信
```

archive → export → upload の順に行う。ビルド番号は asc が自動で採番する(`manageAppVersionAndBuildNumber`)。バージョンは `App/TabiMemo.xcodeproj/project.xcproj` の `MARKETING_VERSION`。

## 確認済み(2026-10-04)

`scripts/testflight.sh 6818975282` で Build 1(version 1.0)のアップロードまで成功(`processingState: VALID`)。内部グループ `Internal`(全ビルドにアクセス)を作成し、テスター `a@art.jp` を追加済み(招待メール送信、`akidon0000@gmail.com` は `Tester(s) cannot be assigned` で追加できなかった)。内部テスターは処理済みの全ビルドを自動で使える。

- 2026-10-05: Build 2(version 1.0、リファクタリングと FB-1〜FB-9)をアップロード(`--notify` なし)。`processingState: VALID`。
- 2026-10-05: Build 3(version 1.0、道なりの線・最初のピンの選択・長押しで追加。要件 0003)を `feature/route-and-long-press` ブランチからアップロード(`--notify` なし)。`processingState: VALID`。
- 2026-10-06: Build 4(version 1.0、青い実線・経路編集(1つ戻す・すべて戻す)・線に沿った再生と写真の拡大。要件 0003〜0005)を `feature/route-and-long-press` ブランチからアップロード(`--notify` なし)。`processingState: VALID`。Build 3 から、経路編集と再生が加わった。
- SwiftLint のビルドツールプラグインを使うため、archive に `-skipPackagePluginValidation` を渡している(`scripts/testflight.sh`)。

## 注意

- アプリアイコンは仮の画像(グラデーションにピン)。差し替えるときは `AppIcon.appiconset/icon-1024.png`(1024px・透過なし)。
- Foundation Models / PCC による提案は、実機で初めて動作を確認できる。TestFlight で確認すること。
- 配信対象は iOS 27 以降([ADR 0009](../adr/0009-clean-architecture.md))。Apple Intelligence が使えない端末では提案欄が出ない。
- Build 2 以降は、保存データの形が変わったため、Build 1 で入れた写真は引き継がれない。

## 開発中の実機確認(OTA)

TestFlight を待たずに実機で試したいときの手順([ADR 0016](../adr/0016-ota-ipa.md))。`build/` は git に入れていない。別のマシンで clone した場合も、下の準備をすれば同じように使える。

### 準備(マシンごとに1回)

| 項目 | 内容 |
|---|---|
| Xcode | 27 以降。`xcode-select -s` で向ける。Xcode にチーム `XSC9AJPSP3` の Apple ID でサインインしておく(自動署名と `-allowProvisioningUpdates` に使う) |
| iPhone の登録 | iPhone の UDID が開発チームに登録されていること。未登録なら、iPhone を USB で Mac につなぎ、Xcode の Devices and Simulators で認識させるか、Apple Developer の Devices に追加する。登録後はプロファイルが自動で更新される |
| Tailscale | Mac と iPhone の両方が同じ tailnet に接続している。tailnet の管理画面で MagicDNS と HTTPS 証明書を有効にしておく(OTA は HTTPS が必須) |
| コマンド | `tailscale`(CLI)と `python3` が PATH にあること |

### 実行

```bash
scripts/ota.sh              # archive → export → 配信(簡易サーバー + tailscale serve)
scripts/ota.sh --no-serve   # ipa と manifest を build/ota/ に作るだけ
```

- 終わると、iPhone で開く URL(`https://<Mac の ts.net 名>/tabimemo/`)が出る。iPhone の Safari で開くと、インストールの確認ダイアログが自動で出る(出ないときはリンクをタップ)。「インストール」を押すと入る。確認ダイアログ自体は iOS の仕様で省けない。
- ページには、ipa の作成時刻・バージョン・コミット・前回のビルド・直近10回の履歴が出る。履歴は `build/ota-history.json` に溜まる(マシンごと。git 管理外なので、別のマシンでは空から始まる)。
- ビルド番号は Development 署名では常に 1。世代の区別は作成時刻とコミットで見る。

### 仕組みと注意

- `build/ota/` に `TabiMemo.ipa`・`manifest.plist`・`index.html` を作り、`python3 -m http.server`(127.0.0.1:8099)で配る。`tailscale serve` の `/tabimemo` をそこへプロキシする。macOS 版の Tailscale は `serve` でフォルダを直接配れないため。
- `tailscale serve` の他のパス(例: `/` の 8080)には触れない。`ota.sh` は 8099 を使っているプロセスを止めて立て直すので、他の用途と衝突するなら `ota.sh` の `PORT` を変える。
- 簡易サーバーは Mac の再起動で止まる。`scripts/ota.sh` をもう一度実行すれば立て直る。
- 配信をやめるとき: `tailscale serve --set-path /tabimemo off`、と 8099 のプロセスを止める(`lsof -ti tcp:8099 | xargs kill`)。
- 署名は `scripts/ExportOptions-dev.plist`(Development・自動署名)。Bundle ID やチームを変えたらここも直す。
