# 開発手順

- 読み手: 開発者本人・エージェント
- 目的: ビルドから画面確認までを、毎回同じ手順でできるようにする

## 前提

- Xcode 27 以降が必要。プロジェクトは JSON 形式の `TabiMemo.xcodeproj/project.xcproj` を git で管理する。生成の手順はない（[ADR 0012](../adr/0012-xcode-json-project.md)）。
- 対象は iOS 27 以降（`project.xcproj` の `IPHONEOS_DEPLOYMENT_TARGET`）。コードの構成は [architecture.md](architecture.md)。確認は iPhone 18 Pro のシミュレーターで行っている。
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
xcodebuild test -scheme TabiMemo -destination 'id=<シミュレーターの UDID>' -skipPackagePluginValidation
```

`TabiMemo` スキームで、`DomainTests` / `DataLayerTests` / `TabiMemoTests` をまとめて動かす。層ごとに動かすときは、スキームを `Domain` / `DataLayer` にする。

## ファイル・ターゲット・設定を変える

| したいこと | やり方 |
|---|---|
| ソースやテストを足す・消す | 該当フォルダ（`Domain/Sources` など）に置く・消すだけ。各ターゲットはフォルダごと読む（同期フォルダ）ので、`project.xcproj` は書き換えない |
| ビルド設定を変える | `project.xcproj` の `build-settings` を書き換える。`xcrun xcodeproj setting` でもよい |
| ターゲット・依存を足す | `project.xcproj` の `targets` と、フォルダの `target-membership` を書き換える |
| 書き換えた後 | `xcrun xcprojformatter --update TabiMemo.xcodeproj` で並び順を整える（差分を小さく保つ） |

- `project.xcproj` は JSON（末尾のカンマを許す）。コメントは書けないので、設定の理由はこの handbook か ADR に書く。
- アプリの Info.plist は `TabiMemo/Info.plist`。フレームワークとテストの Info.plist はビルド時に生成する（`GENERATE_INFOPLIST_FILE`）。
- スキームは `TabiMemo.xcodeproj/xcshareddata/xcschemes/` に置いた共有スキーム。テスト対象の追加はここを書き換える。
- SwiftLint のバージョンは `project.xcproj` の `packages`、解決結果は `project.xcworkspace/xcshareddata/swiftpm/Package.resolved`。

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
