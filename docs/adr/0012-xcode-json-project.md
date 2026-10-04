# 0012: Tuist をやめ、Xcode の JSON 形式のプロジェクトをそのまま管理する

- 状態: 有効
- 読み手: 将来の自分・エージェント
- 日付: 2026-10-05

## 決定

- プロジェクトは `TabiMemo.xcodeproj/project.xcproj`(Xcode 27.2 で入った JSON 形式)を git で管理する。Tuist(`Project.swift`)と生成の手順はなくす。XcodeGen も使わない。
- 各ターゲットのソースは、フォルダごとに割り当てる(同期フォルダ。`"kind": "folder"`)。ファイルの追加・削除でプロジェクトファイルは変わらない。
- アプリの Info.plist は `TabiMemo/Info.plist` に置く。フレームワークとテストの Info.plist はビルド時に生成する。
- 共有スキーム(`TabiMemo` / `Domain` / `DataLayer`)も `TabiMemo.xcodeproj` の中に置いて管理する。SwiftLint のバージョンは `project.xcproj` で1つに固定し、`Package.resolved` は管理しない(置いても数秒で消えた。原因は未特定)。
- 書き換えた後は `xcrun xcprojformatter --update TabiMemo.xcodeproj` で整える。

## 背景

Tuist を使っていたのは、`project.pbxproj` が人にも AI にも読めず、マージで壊れやすかったからだった。Xcode 27.2 で、`project.pbxproj` の代わりに JSON の `project.xcproj` を使えるようになった。Xcode 27.0 以降で開ける。読める形式になったので、生成のための別の道具を挟む理由が薄くなった。

Tuist には、ファイルを足したら `tuist generate` を忘れると `Build input files cannot be found` で失敗する、という落とし穴もあった。同期フォルダにすると、この手順そのものがなくなる。

## 比較

| 案 | 内容 | 採否 |
|---|---|---|
| A. Tuist を続ける | Swift で書いた定義から生成する | 不採用(生成の手順が増える。xcodeproj を管理しないので、Xcode で変えた設定が残らない) |
| B. XcodeGen | YAML から生成する | 不採用(A と同じく生成の手順が要る) |
| C. JSON の `project.xcproj` を直接管理 | Xcode 27.2 の形式 | 採用 |

## 割り切り・注意

- Xcode 26 以前では開けない(配信対象も iOS 27 以上なので、Xcode 27 は元々必要)。
- JSON なのでコメントを書けない。設定の理由は handbook・ADR に書く。
- 生成の仕組みが持っていた、共通設定のテンプレートのような機能はない。ターゲット共通の設定は、プロジェクト全体の `build-settings` に置いている。
- 変換は `xcodebuild -convert-project "Xcode Project"` でできた。ただし Tuist の生成物を変換すると、`Derived/` やファイルごとの列挙が残る。そのため、変換結果を参考に、フォルダ単位で書き直した(約250行)。
- `project.pbxproj` へ戻す変換は、コマンドラインではできなかった。戻すなら、git でこのコミットより前に戻す。

## 確認したこと(2026-10-05)

- `xcodebuild test`(`TabiMemo` スキーム)で、3つのテストターゲット 38 件が通る。SwiftLint のプラグインも動く。
- `Domain/Sources` にファイルを1つ足しただけで、プロジェクトファイルを変えずにビルドに入った。
- シミュレーターで起動し、地図画面が出る。Info.plist の表示名・バックグラウンド位置情報の設定が入っている。

## 参考

- [Xcode 27.2 Release Notes](https://developer.apple.com/documentation/xcode-release-notes/xcode-27_2-release-notes)
- [Updating your Xcode project configuration file format](https://developer.apple.com/documentation/xcode/updating-your-xcode-project-configuration-file-format)
- [apple/xcode-project-format](https://github.com/apple/xcode-project-format)
- 手順: [handbook/development.md](../handbook/development.md)
