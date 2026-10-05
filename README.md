# 旅メモ

旅行中に撮った写真をピンとして地図に残し、後から軌跡をカメラでなぞる「リプレイ」で辿り直せる iOS アプリ。

## 解く課題

- 旅の写真はカメラロールに溜まるだけで、どこで撮ったか・どう繋がっていたかがすぐ失われる。
- Relive のような「軌跡をカメラが飛びながら辿る」体験を、位置情報を撮るたびに残しておける個人用アプリとして作る。

## MVP スコープ

- 対応 OS: iOS のみ（iPadOS / macOS はコンパニオンアプリとして将来対応）
- トリップは「開始」「終了」を明示操作。実行中はバックグラウンドでも位置情報を継続記録する（`Always` 権限 + Background Modes: Location）
- 記録は間引きサンプリング、リプレイ再生時にソフトウェア側で軌跡を補間して滑らかに見せる
- 写真はアプリ内カメラでの撮影、およびトリップ終了後もその時間範囲内で Photos ライブラリからさかのぼって取り込み可能（EXIF 位置情報 → なければ地図タップで手動配置）
- **核となる機能**: MapKit のカメラが軌跡をなぞりながら飛び、写真ピンで一時停止するアニメーション付きリプレイ
  - ペーシングは時間ベース / 密度ベースの2方式を実装し、Settings 画面のトグルでアプリ全体のデフォルトを切り替え可能にする
  - 動画エクスポート（`.mp4`、無音・横向き）にも対応
- データは端末ローカルのみ（SwiftData、CloudKit 同期なし）
- 地図は Apple MapKit

## ロードマップ

→ [ROADMAP.md](ROADMAP.md)

## 開発環境

- Xcode 27 以降が必要。アプリのプロジェクトは JSON 形式の `TabiMemo.xcodeproj/project.xcproj`(殻だけ)。コードは Swift Package の `Domain/` `DataLayer/` `Features/` に分けている([ADR 0012](docs/adr/0012-xcode-json-project.md)、[ADR 0013](docs/adr/0013-swift-packages.md))
- SwiftUI + SwiftData、Swift 6 strict concurrency。構成は [docs/handbook/architecture.md](docs/handbook/architecture.md)

```bash
make xcode-open # Xcode で開く
```
