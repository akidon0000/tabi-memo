# 0013: 層と画面を Swift Package に分け、アプリのプロジェクトは殻だけにする

- 状態: 有効
- 読み手: 将来の自分・エージェント
- 日付: 2026-10-05

## 決定

コードを3つの Swift Package と、アプリの Xcode プロジェクトに分ける。

| 場所 | 中身 | 依存してよいもの |
|---|---|---|
| `Domain/`(パッケージ) | `Domain`(Entity・Rule・プロトコル・UseCase)、`TestSupport`(テスト用の偽物) | Foundation だけ |
| `DataLayer/`(パッケージ) | SwiftData・ImageIO・FoundationModels の実装 | Domain |
| `Features/`(パッケージ) | `SharedUI`(共通部品)と、画面ごとのモジュール(`TripMapFeature` など) | Domain、`SharedUI`、他の画面(下の表) |
| `TabiMemo/`(Xcode プロジェクト) | 起動(`TabiMemoApp`)と組み立て(`AppDependencies`)、Assets、Info.plist だけ | 上のすべて |

画面どうしの依存は次のとおり。逆向きの import はビルドが失敗する。

| 画面のモジュール | 依存する画面 |
|---|---|
| `TripMapFeature`(地図。入口) | `PhotoListFeature` `AddPhotosFeature` `EditPhotoFeature` `RecentlyDeletedFeature` |
| `PhotoListFeature` | `EditPhotoFeature` |
| `AddPhotosFeature` `EditPhotoFeature` `RecentlyDeletedFeature` | なし |

[ADR 0009](0009-clean-architecture.md) の層の構成・依存の向き・UseCase の決まりは変えない。変わるのは、境界を守る単位が「Xcode のターゲット」から「Swift Package のターゲット」になることと、画面ごとに分けることだけ。

## 背景

参考にしたいリポジトリ(try-swift-tokyo)が、Xcode プロジェクトを殻だけにして、中身をパッケージと機能ごとのモジュールに分けていた。[ADR 0012](0012-xcode-json-project.md) で、JSON のプロジェクトに6つのターゲットを書いたところ、`project.xcproj` が約250行になった。パッケージにすると、依存は `Package.swift` に書け、`project.xcproj` は殻の1ターゲットだけになる。

## 比較

| 案 | 内容 | 採否 |
|---|---|---|
| A. いまのまま | Xcode のターゲット3つ + 画面はフォルダ分け | 不採用(ターゲットの追加で `project.xcproj` に50行ずつ増える) |
| B. 層だけパッケージ | Domain・DataLayer・画面全体を各1つ | 不採用(画面の依存が、フォルダの約束だけで守られる) |
| C. 層と画面をパッケージ | 上の決定 | 採用 |

## 決めたこと・割り切り

- 別のモジュールから使う型・イニシャライザ・メソッドには、`public` が要る。ADR 0009 は「AI が読みやすい」ことを優先して機能ごとの分割を見送ったが、これを承知で分ける(分割を指示されたため)。`public` を付け忘れると、ビルドが教えてくれる。
- 画面どうしの作り方は、`TripMapChildren`(子画面の ViewModel を作る関数の束)で渡す。`AppDependencies` を `@Environment` に置く方式はやめた。画面が、組み立てを担う型を知らなくて済む。
- 地図でしか使わない部品(下のパネル・写真の拡大・ピン・距離の計算)は `TripMapFeature` に置く。複数の画面で使うものだけを `SharedUI` に置く(`LocationPinPicker`、座標と画像の変換)。
- SwiftLint のプラグインは各パッケージの `Package.swift` に書く(0.65.1 に固定)。設定は、直下の `.swiftlint.yml` を各パッケージの `.swiftlint.yml` の `parent_config` で引き継ぐ。
- 既定のアクターの設定(`SWIFT_DEFAULT_ACTOR_ISOLATION`)は、パッケージでは `swiftSettings: [.defaultIsolation(MainActor.self)]` で書く。Domain は何も書かない(nonisolated)。
- テストは各パッケージの `Tests/` に置き、`scripts/test.sh` でまとめて動かす。アプリのスキームではテストを動かさない(テストはパッケージのスキーム `Domain-Package` などで動く)。
- `TestSupport`(偽物)は `Domain` パッケージの別のプロダクトにして、`Features` のテストからも使う。

## 見直しのタイミング

- 画面が増えて、`Features/Package.swift` が長くなったとき(画面ごとのパッケージに分ける)。
- 画面どうしの依存が、`TripMapChildren` のような束では扱えなくなったとき。

## 参考

- [try-swift-tokyo](https://github.com/tryswift/try-swift-tokyo)(`App/` が殻、`Conference/` が機能ごとのモジュール)
- 規約と手順: [handbook/architecture.md](../handbook/architecture.md)
