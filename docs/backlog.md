# backlog

- 読み手: 自分・エージェント(個人スキル `pv-from-feedback` が更新する)
- 目的: TestFlight の FB から出た項目の、いまの状態を1枚で見る

状態: 受付 → 再現待ち / ヒアリング中 → 要件確定 → 実装中 → 配信済み(Build N) → 完了

| ID | 種別 | 内容 | 出どころ | 優先度 | 状態 | 要件 |
|---|---|---|---|---|---|---|
| FB-1 | 新機能 | 写真を削除する動線がない | [2026-10-04](feedback/2026-10-04.md) | 高(消せないとテストデータが残る) | 配信済み(Build 2) | [0001](requirements/0001-delete-photos.md) |
| FB-2 | 新機能 | 地図上に、写真の並び順に線を引く | 同上 | 中 | 配信済み(Build 2)・要件の確認待ち | [0002](requirements/0002-map-and-panel-feedback.md) |
| FB-3 | 体験の改善 | 地図で写真ピンが重なったとき、正方形の中にグリッド状にまとめて出す(サイズは変えない) | 同上 | 中 | 配信済み(Build 2)・要件の確認待ち | [0002](requirements/0002-map-and-panel-feedback.md) |
| FB-4 | バグ | 下部パネルを上へ動かし切ったとき、初期位置から再度動き出してカクつく | 同上 | 高(基本操作) | 配信済み(Build 2)。原因はコードから特定、実機で再現確認はしていない | [0002](requirements/0002-map-and-panel-feedback.md) |
| FB-5 | 体験の改善 | 写真を追加したら、全部が画面に収まるよう地図を拡大縮小する | 同上 | 高 | 配信済み(Build 2)・要件の確認待ち | [0002](requirements/0002-map-and-panel-feedback.md) |
| FB-6 | 体験の改善 | 写真を指定した時点で AI がタイトル案・メモ案を作り、入力欄の薄い文字で見せ、「適用」で入れる | 同上 | 高(この機能の要) | 配信済み(Build 2)。実機で未確認(シミュレーターでは AI が使えない) | [0002](requirements/0002-map-and-panel-feedback.md)・[ADR 0011](adr/0011-ai-suggestion-placeholder.md) |
| FB-7 | 体験の改善 | 全開のとき、メモと写真を同時にスライドさせる | 同上 | 中 | 配信済み(Build 2)。全開だけページごと滑らせる | [0002](requirements/0002-map-and-panel-feedback.md)・[ADR 0010](adr/0010-full-panel-page-slide.md) |
| FB-8 | 体験の改善 | 全開で下へスクロールすると、同時にモーダルも閉じる | 同上 | 中 | 配信済み(Build 2)。コンパクトへ畳む | [0002](requirements/0002-map-and-panel-feedback.md) |
| FB-9 | 体験の改善 | 左右にスワイプするとき、写真を薄くしなくてよいかもしれない | 同上 | 低 | 配信済み(Build 2) | [0002](requirements/0002-map-and-panel-feedback.md) |

## 開発者本人の依頼(FB ではないもの)

| ID | 内容 | 状態 | 要件 |
|---|---|---|---|
| R-1 | 写真を結ぶ白い破線を道なりにする | 配信済み(Build 3) | [0003](requirements/0003-route-first-pin-long-press.md)・[ADR 0014](adr/0014-route-along-roads.md) |
| R-2 | 開いたとき、撮影順で最初のピンを選んでおく | 配信済み(Build 3) | [0003](requirements/0003-route-first-pin-long-press.md) |
| R-3 | 地図の長押しで、その場所に写真を追加する | 配信済み(Build 3) | [0003](requirements/0003-route-first-pin-long-press.md) |
| R-5〜R-11 | 経路編集モード(「…」→「経路を編集」。青い線を長押ししてドラッグすると経由点が付き(何か所でも)、道なりに引き直す。1つ戻す・すべて戻す。保存する。地図を止める案・止めない案の2案を見比べ中) | 実装済み・未配信 | [0004](requirements/0004-route-edit-mode.md)・[ADR 0015](adr/0015-route-waypoints.md) |
| R-12〜R-16 | 線に沿った再生(右上の ▶。目印が青い線に沿って動き、写真の場所で止まる) | 実装済み・未配信 | [0005](requirements/0005-route-playback.md) |
| R-4 | 位置情報の取り込み(HealthKit・写真ライブラリの位置と時刻・Google タイムライン) | 未着手。取り込み元を決めてから要件を書く | - |

## 既知の積み残し(FB ではなく、実装中に分かったもの)

| 内容 | メモ |
|---|---|
| 並べ替えで既存写真の日時も書き換わる | 日時とは別に並び順を持つ案がある。要判断 |
| GPS なし写真の地図ピン指定・AI 提案の実機動作 | 実機で未確認 |
| Build 2 | 2026-10-05 にアップロード(通知なし)。Internal グループは全ビルドを使えるので、テスターは入れ替えられる。Build 1 の保存データは引き継がれない([ADR 0009](adr/0009-clean-architecture.md)) |
