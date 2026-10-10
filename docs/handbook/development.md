# 開発手順

- 読み手: 開発者本人・エージェント
- 目的: ビルドから画面確認までを、毎回同じ手順でできるようにする

## 前提

- Xcode 27 以降が必要。アプリのプロジェクトは JSON 形式の `App/TabiMemo.xcodeproj/project.xcproj` を git で管理する（[ADR 0012](../adr/0012-xcode-json-project.md)）。コードは Swift Package の `App/Domain/` `App/DataLayer/` `App/Features/` に分けてあり、プロジェクトは殻の1ターゲットだけ（[ADR 0013](../adr/0013-swift-packages.md)）。
- 対象は iOS 27 以降（`project.xcproj` の `IPHONEOS_DEPLOYMENT_TARGET` と、各 `Package.swift` の `platforms`）。コードの構成は [architecture.md](architecture.md)。確認は iPhone 18 Pro のシミュレーターで行っている。
- bundle id: `com.akidon0000.tabimemo`

## ビルド

```bash
xcodebuild -scheme TabiMemo -configuration Debug \
  -destination 'id=<シミュレーターの UDID>' -skipPackagePluginValidation build
```

- `-skipPackagePluginValidation` は、SwiftLint のビルドツールプラグインを確認なしで動かすために付ける。付けないと、コマンドラインのビルドが止まる。
- SwiftLint の警告・エラーはビルドの出力に出る。エラーがあるとビルドは失敗する。

## テスト

```bash
scripts/test.sh            # Domain / DataLayer / Features をまとめて動かす(iPhone 18 Pro)。失敗があると終了コード 1
scripts/test.sh <UDID>     # シミュレーターを指定する
```

1つのパッケージだけ動かすときは、そのフォルダで次のようにする(スキーム名は、プロダクトが複数あるパッケージ(`Domain`、`Features`)では `<名前>-Package`、1つだけの `DataLayer` では `DataLayer`)。

```bash
cd App/Features && xcodebuild test -scheme Features-Package \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro' -skipPackagePluginValidation
```

アプリのスキーム(`TabiMemo`)ではテストを動かさない。テストはパッケージの中にある。

## ファイル・モジュール・設定を変える

| したいこと | やり方 |
|---|---|
| ソースやテストを足す・消す | 該当モジュールのフォルダ(`App/Features/Sources/TripMapFeature/` など)に置く・消すだけ。`Package.swift` は書き換えない |
| 画面や層のモジュールを足す | 該当パッケージの `Package.swift` に、ターゲット(と `products`)を足す。画面は `feature("XxxFeature")` の1行。層は、同じ種類の既存のターゲットを写す。使い方は [architecture.md](architecture.md) の「画面を1つ足す」 |
| アプリのビルド設定を変える | `project.xcproj` の `build-settings` を書き換える。`xcrun xcodeproj setting` でもよい。書き換えた後は `xcrun xcprojformatter --update App/TabiMemo.xcodeproj` |
| パッケージの設定を変える | `Package.swift` の `swiftSettings` など。既定のアクターは `.defaultIsolation(MainActor.self)`(Domain は付けない) |
| アプリがパッケージのプロダクトを使う | `project.xcproj` の `packages` と、ターゲットの `dependencies`・`package-product-members` に足す(既存の行を写す) |

- `project.xcproj` は JSON（末尾のカンマを許す）。コメントは書けないので、設定の理由はこの handbook か ADR に書く。
- アプリの Info.plist は `App/TabiMemo/Info.plist`。
- スキームは `App/TabiMemo.xcodeproj/xcshareddata/xcschemes/TabiMemo.xcscheme` の1つだけ。
- SwiftLint のバージョンは、各 `Package.swift` と `project.xcproj` の `packages` で 0.65.1 に固定している。設定は `App/.swiftlint.yml` を、各パッケージの `.swiftlint.yml`(`parent_config`)で引き継ぐ。`Package.resolved` は git に入れていない(下の注意)。
- 注意: このマシンでは、`project.xcworkspace/xcshareddata/swiftpm/Package.resolved` を置いても、数秒で消える(2026-10-05 確認。何が消しているかは未特定)。バージョンを固定しているので、ビルドの再現性には影響しない。

## 起動と確認

1. シミュレーターを起動する（`xcrun simctl boot <UDID>`）。
2. ビルド成果物（`~/Library/Developer/Xcode/DerivedData/TabiMemo-*/Build/Products/Debug-iphonesimulator/TabiMemo.app`）を起動する。`TabiMemo-*` が複数あるときは更新日時が新しい方。
3. 起動直後は地図の読み込みが終わるまで数秒、タップが効かない。ピンを押す前に待つ。

## デモデータを入れ直す

デモ（渋谷→代々木公園の3枚）は**初回起動時だけ**入る。データモデルやデモの内容を変えたら、アプリを消して入れ直す。

```bash
xcrun simctl uninstall <UDID> com.akidon0000.tabimemo
```

SwiftData のスキーマを変えた（`PhotoRecord` にプロパティを足したなど）ときも同じ。

## スクリーンショット

```bash
xcrun simctl io <UDID> screenshot --type=png path/to/out.png
sips --resampleWidth 603 path/to/out.png   # リポジトリに置く前に縮める
```

- `<UDID>` を省略すると失敗する場合がある。明示する。
- 地図の読み込み前や、アニメーションの途中を撮ってしまうことがある。撮った画像を必ず開いて確認する。
- 横スワイプの途中など、指を置いたままの状態は、スクリーンショット取得と指の離れるタイミングが合わず、撮りにくい。
- 画像は `docs/specs/images/` に置く。幅 603px にそろえている。

## 確認の定番手順

| 見たいもの | 操作 |
|---|---|
| コンパクト | ピンをタップする（コンパクトで開く） |
| ハーフ | コンパクトでバーをタップする |
| 全開 | ハーフでバーをタップする |
| 全開から畳む | × を押す。または上部のバーを下に引く |
| 前後の写真 | 全開で左右にスワイプする |
