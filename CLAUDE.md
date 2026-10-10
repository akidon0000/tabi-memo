# TabiMemo

旅の写真を地図に置いて、メモと一緒に残す iOS アプリ。正本は [docs/](docs/README.md)。
**構成・手順・判断を変えたら、docs への記録もセットで行う。**

- **コードを書く前に [docs/handbook/architecture.md](docs/handbook/architecture.md) を読む**(層・命名・数値の上限・画面や UseCase の足し方)
- 画面の挙動 → `docs/specs/` / 判断の経緯 → `docs/adr/`(新番号で起票、索引も更新)/ 手順 → `docs/handbook/`
- ビルド・確認 → [docs/handbook/development.md](docs/handbook/development.md)。「ビルドして」は `.claude/skills/build`(シミュレーターで起動 + 実機用の OTA 配信まで行う)
- 配信(TestFlight) → [docs/handbook/release.md](docs/handbook/release.md)。配信後の外への連絡は、内容を見せて確認してから
- FB を元にした進め方 → 個人スキル `pv-from-feedback`(hq 管理)。要件をユーザーが確認するまで実装しない。状態は [docs/backlog.md](docs/backlog.md)
