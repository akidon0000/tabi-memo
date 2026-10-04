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

`tuist generate` → archive → export → upload の順に行う。ビルド番号は asc が自動で採番する(`manageAppVersionAndBuildNumber`)。バージョンは `Project.swift` の `MARKETING_VERSION`。

## 確認済み(2026-10-04)

`scripts/testflight.sh 6818975282` で Build 1(version 1.0)のアップロードまで成功(`processingState: VALID`)。内部グループ `Internal`(全ビルドにアクセス)を作成し、テスター `a@art.jp` を追加済み(招待メール送信、`akidon0000@gmail.com` は `Tester(s) cannot be assigned` で追加できなかった)。内部テスターは処理済みの全ビルドを自動で使える。

## 注意

- アプリアイコンは仮の画像(グラデーションにピン)。差し替えるときは `AppIcon.appiconset/icon-1024.png`(1024px・透過なし)。
- Foundation Models / PCC による提案は、実機で初めて動作を確認できる。TestFlight で確認すること。
- 配信対象は iOS 27 以降([ADR 0009](../adr/0009-clean-architecture.md))。Apple Intelligence が使えない端末では提案欄が出ない。
- Build 2 以降は、保存データの形が変わったため、Build 1 で入れた写真は引き継がれない。
