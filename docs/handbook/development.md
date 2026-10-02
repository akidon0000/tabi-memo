# 開発手順

- 読み手: 開発者本人・エージェント
- 目的: ビルドから画面確認までを、毎回同じ手順でできるようにする

## 前提

- Tuist でプロジェクトを生成する。`TabiMemo.xcodeproj` / `.xcworkspace` / `Derived/` は git 管理外。
- 対象は iOS 26 以降（`Project.swift`）。確認は iPhone 18 Pro のシミュレーターで行っている。
- bundle id: `com.akidon0000.tabimemo`

## ビルド

```bash
tuist generate --no-open   # ファイルを増減したら必ず
xcodebuild -scheme TabiMemo -configuration Debug \
  -destination 'id=<シミュレーターの UDID>' build
```

ファイルを削除・追加したあとに `tuist generate` を忘れると、`Build input files cannot be found` で失敗する。

## 起動と確認

1. シミュレーターを起動する（`xcrun simctl boot <UDID>`）。
2. ビルド成果物（`~/Library/Developer/Xcode/DerivedData/TabiMemo-*/Build/Products/Debug-iphonesimulator/TabiMemo.app`）を起動する。`TabiMemo-*` が複数あるときは更新日時が新しい方。
3. 起動直後は地図の読み込みが終わるまで数秒、タップが効かない。ピンを押す前に待つ。

## デモデータを入れ直す

デモ（渋谷→代々木公園の3枚）は**初回起動時だけ**入る。データモデルやデモの内容を変えたら、アプリを消して入れ直す。

```bash
xcrun simctl uninstall <UDID> com.akidon0000.tabimemo
```

SwiftData のスキーマを変えた（`TripPhoto` にプロパティを足したなど）ときも同じ。

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
