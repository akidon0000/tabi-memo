# 0009 クリーンアーキテクチャにし、層の境界をターゲットで守る

- 状態: 有効(「機能ごとのモジュール分割はしない」と、層を Xcode のターゲットで分ける点は [ADR 0013](0013-swift-packages.md) で置き換えた。層の構成と依存の向きは、そのまま)
- 日付: 2026-10-05

## 決定

コードを Domain / DataLayer / App の3つのターゲットに分ける。依存は App → DataLayer → Domain の一方向にし、逆向きの import はビルドエラーにする。

| 層 | 持つもの | 依存してよいもの |
|---|---|---|
| Domain | Entity(純粋な struct)、Rule(純粋な計算)、Repository・Service のプロトコル、UseCase | Foundation だけ |
| DataLayer | SwiftData の `@Model`(`〜Record`)、Repository の実装、ImageIO・FoundationModels の実装 | Domain、Apple のフレームワーク |
| App | View と `@Observable` の ViewModel、組み立て(`AppDependencies`) | Domain、DataLayer、SwiftUI・MapKit・PhotosUI |

あわせて、次のことも決めた。

- UseCase は1つの操作を1つの型にし、`execute` を1つだけ持たせる。
- 画面の更新は、Repository が `AsyncStream` で流す最新の値に任せる。保存の後に ViewModel が読み直す処理は書かない。中身は iOS 27 の `ResultsObserver` と `Observations` で作る。
- 配信対象を iOS 27 以上に上げ、OS による分岐をなくす。
- `@Model` のクラス名を `〜Record` に変えた。保存データの互換は捨てる(TestFlight の Build 1 のデータは消える)。
- SwiftLint をビルドツールプラグインで入れ、ファイルの行数などの上限を機械で守らせる。

## 背景

このアプリのコードは、大半を AI が書く。性能の低いモデルでも迷わず直せることを第一に、人間が読んでデバッグしやすいことを第二に置いた。

以前の構成には、次の問題があった。
- 画面のコードが `modelContext` を直接触っていて、保存の処理が5か所に散っていた。
- `TripDetailView` は340行、`CustomSheetView` は667行あった。

途中まで進めた再編の下書き(`wip/clean-arch-draft` ブランチ)もあった。ただし `@Model` を Domain に置いたままで、`ModelContext` がプロトコル越しに漏れており、ビルドも通らなかった。

## 比較

| 論点 | 採用 | 比べた案 | 採用の理由 |
|---|---|---|---|
| Domain の型 | 純粋な struct + Record との変換 | `@Model` を Domain で使う | Domain が SwiftData に依存しない。iOS のクリーンアーキテクチャの解説で最も多い形で、学習ソースと一致する |
| 境界の守り方 | ターゲットを分ける | フォルダ分けだけ | 依存の向きを破ると、ビルドが失敗して気づける |
| 状態管理 | MVVM(`@Observable`)+ イニシャライザ注入 | TCA、swift-dependencies | 標準の書き方で学習ソースが最も多い。外部ライブラリの作法を覚えなくてよい |
| UseCase の粒度 | 1操作1型 | 対象ごとにまとめる | 直す場所が名前から1つに決まる |
| 画面の更新 | `ResultsObserver` のストリーム | 保存のたびに読み直す | 読み直し忘れの不具合が起きない |
| 規約の守り方 | SwiftLint(プラグイン) | 文書だけ | どの環境でも同じ版で検査される |

## 却下した案

- **TCA**: 厳密だが作法が独特で、低スペックのモデルほど崩す。
- **機能ごとのモジュール分割**: この規模では分けすぎになる。
- **iOS 26 を残して2系統で書く**: OS による分岐は、片方だけ直して壊す原因になる。

## 見直しのタイミング

- 画面が10を超え、App ターゲットのビルドが遅くなったとき(機能ごとのモジュール分割を検討する)。
- `ResultsObserver` の挙動に不具合が見つかったとき。

## 参考

- 規約と手順: [docs/handbook/architecture.md](../handbook/architecture.md)
- WWDC26「What's New in SwiftData」(`ResultsObserver` / `HistoryObserver`)
- 決定までの質疑: 2026-10-04〜05 のセッション(pv-grilling)
