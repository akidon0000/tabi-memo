# 0017: コードを App/ にまとめ、ルートは docs・scripts・設定だけにする

- 状態: 有効
- 読み手: 将来の自分・エージェント
- 日付: 2026-10-11

## 決定

`Domain/` `DataLayer/` `Features/` `TabiMemo/`(アプリの Info.plist・Assets・起動)`TabiMemo.xcodeproj` と `.swiftlint.yml` を、リポジトリ直下の `App/` に移す。ルートに残すのは `docs/` `scripts/` `README.md` `CLAUDE.md` `Makefile` などの運用物だけ。

[ADR 0013](0013-swift-packages.md) の層・パッケージ・依存の向きは変えない。変わるのは置き場所だけ。

## 背景

ルートに、コード(5つ)と運用物(docs・scripts・Makefile・各種 md)が混ざって並んでいた。ビルド・テスト・配信のスクリプトも増えて、「コードはどこまでか」が一目で分からなくなった。

## 決めたこと・割り切り

- `.swiftlint.yml` は `App/` に置く。`project.xcproj` の `.swiftlint.yml` 参照(プロジェクトからの相対パス)と、各パッケージの `parent_config: ../.swiftlint.yml` が、どちらも書き換えずに済む。
- `scripts/` `docs/` は動かさない。スクリプトは `App/` 配下のパスを使う(`xcodebuild -project App/TabiMemo.xcodeproj`、パッケージのテストは `cd App/<名前>`)。`build/` はルートのまま。
- 過去の ADR・仕様の GitHub パーマリンク(コミット SHA 固定)は、当時のパスのまま残す。リンクは過去のコミットを指すので壊れない。
- 古い ADR 本文の `Features/` などの表記は、書いた時点の場所のまま。現在の場所は handbook を見る。

## 見直しのタイミング

- `App/` の中に、アプリ以外のターゲット(Widget など)が増えて、置き場所を分けたくなったとき。
