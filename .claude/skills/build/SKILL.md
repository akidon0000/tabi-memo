---
name: build
description: TabiMemo をビルドして、シミュレーターで動かし、実機用の OTA 配信(ipa)も用意する。「ビルドして」「アプリ動かして」「実機に入れたい」等で使用する。
---

# TabiMemo のビルド(シミュレーター起動 + OTA)

「ビルドして」と言われたら、次の2つを両方行う。片方だけ頼まれたとき(「シミュレーターだけ」「OTA だけ」)はその指示に従う。
手順の正本は `docs/handbook/development.md`(シミュレーター)と `docs/handbook/release.md`(OTA)。ここは実行順だけ書く。

## 0. 前に確認する

- `xcode-select -p` が Xcode 27 以降を指していること。違えば、止めてユーザーに `sudo xcode-select -s <Xcode 27 の Developer>` を頼む(sudo は実行できない)。
- 実機に入れたいだけで、動作確認が不要でも、1 → 2 の順で進める(ビルドが通らない ipa を配らないため)。

## 1. シミュレーターでビルド・起動

1. シミュレーターを選ぶ。起動中(`xcrun simctl list devices booted`)があればそれ、なければ `iPhone 18 Pro`(iOS 27 以降)を `xcrun simctl boot`。同名が複数あるときは UDID で指定する。
2. ビルド:
   ```bash
   xcodebuild -scheme TabiMemo -configuration Debug \
     -destination 'id=<UDID>' -skipPackagePluginValidation build
   ```
   SwiftLint のエラーがあると失敗する。出力から原因を読んで直す。
3. 成果物(`~/Library/Developer/Xcode/DerivedData/TabiMemo-*/Build/Products/Debug-iphonesimulator/TabiMemo.app`。複数あるときは更新日時が新しい方)を `xcrun simctl install` して `xcrun simctl launch <UDID> com.akidon0000.tabimemo` で起動する。
4. 起動直後は地図の読み込みで数秒タップが効かない。見せるときは `xcrun simctl io <UDID> screenshot --type=png <path>` で撮って、画像を開いて確認する(地図の読み込み前を撮りがち)。
5. データモデルやデモを変えた直後は、先に `xcrun simctl uninstall <UDID> com.akidon0000.tabimemo` で入れ直す。

## 2. OTA(実機用の ipa)を用意

```bash
scripts/ota.sh
```

- archive → export → `tailscale serve` での配信まで行う。数分かかるので、バックグラウンドで動かして待つ。
- 終わったら、出力の最後の URL(`https://<Mac の ts.net 名>/tabimemo/`)を伝える。iPhone の Safari で開くと確認ダイアログが出るので、「インストール」を押してもらう(確認は iOS の仕様で省けない)。
- 実機に入ったかは確認できない。入れた結果をユーザーに聞く。
- 失敗の典型: iPhone の UDID が未登録(署名で失敗)、Tailscale が未接続、8099 番ポートの競合。準備は `docs/handbook/release.md` の「準備」を参照。

## 3. 報告

- シミュレーターでビルド・起動できたか(失敗なら出力の該当部分)。
- OTA の URL と、ページに出る作成時刻・コミット。
- 未コミットの変更が入っているビルドなら、そう伝える(ページにも出る)。
