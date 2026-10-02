# CustomSheetView（下部パネル）

- 読み手: パネルを触る・流用する人
- 目的: 使い方と、壊しやすい箇所を共有する
- 設計の理由: [../adr/0002-custom-bottom-panel.md](../adr/0002-custom-bottom-panel.md)

## 使い方

地図の `.overlay` に置く。親は `.ignoresSafeArea()` にする（全開で画面の端まで使うため）。

```swift
CustomSheetView(
    config: $sheetConfig,
    title: "2026年10月2日 21:26",
    caption: "",
    headerImage: photo.image,
    headerAspectRatio: photo.aspectRatio,
    onAdd: { /* 追加ボタン */ },
    canPage: { neighbor($0, of: photo) != nil },
    onPage: { /* 前後へ移る */ },
    neighbor: { step in /* 隣の PageSnapshot */ }
) {
    PhotoMemoView(photo: photo)   // 写真の下に出る中身
}
```

| 引数 | 役割 |
|---|---|
| `config` | 色（`headerTint`）、コンパクトの高さ（`smallestDetentHeight`、既定 64）、写真の最小高さ |
| `headerAspectRatio` | 写真の幅/高さ。縦長なら 1 より小さい |
| `onAdd` | 渡すとコンパクト時だけ右に追加ボタンが出る |
| `canPage` / `onPage` | 左右スワイプで前後へ移れるか／移る処理 |
| `neighbor` | スワイプ中に後ろへ見せる隣の写真（`PageSnapshot`。使うのは写真だけ） |
| 末尾クロージャ | 写真と日時の下に出る中身。全開では一緒にスクロールする |

## 構成の要点

[CustomSheetView.swift](https://github.com/akidon0000/tabi-memo/blob/c36cb71a5fd9165ce3bf1b5b7b44c2258fd6360c/TabiMemo/Sources/Views/Components/CustomSheetView.swift)

- **進行度が2つある。** `progress`（コンパクト→ハーフで 0→1）がヘッダーの変形を、`fullProgress`（ハーフ→全開で 0→1）が白い背景・余白・角丸の消え方を決める。
- **ヘッダーは2層。** 写真・タイトルはスクロール量だけ上へ流れる層。バー・× と白い背景は上に固定された層（写真がこの下をくぐる）。
- **段階の切り替え**は `detent`（`.compact` / `.half` / `.full`）と、バーのタップ・ドラッグ・× が書き換える。

## 壊しやすい箇所

- **ドラッグ座標は `.global`。** パネルの高さが動くので、ローカル座標だと値が揺れて全開まで届かない。
- **全開ではヘッダーのタッチを無効にする。** 下のスクロールに通すため。縦ドラッグは上部の固定行だけが受ける。
- **白い背景はスクロール側ではなく、先読みカードの下に敷く。** スクロール側に敷くと、後ろの先読みカードが隠れる。
- **ガラス（`glassEffect`）は `opacity` で消えない場面がある。** 追加ボタンは `GlassEffectContainer` に入れない。
- **全開の上端**は、ウィンドウの `safeAreaInsets.top` を読んで引く（親が `ignoresSafeArea` のため `GeometryReader` からは取れない）。
- **画面角の半径は非公開キー。** → [ADR 0004](../adr/0004-private-corner-radius.md)
