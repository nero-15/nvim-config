# 06 編集を増幅する — 囲み・ヤンク履歴・変換

> 所要 30 分。この環境に入れてある「vimmer の定番の強い機能」を一通り触る。

## 囲む・変える・外す（surround）

| キー | 動作 | 例 |
|------|------|-----|
| `ys{対象}{囲み}` | 囲む | `ysiw"` 単語を `"` で囲む |
| `cs{古}{新}` | 囲みを変える | `cs"'` `"` を `'` に |
| `ds{囲み}` | 囲みを外す | `ds(` 括弧を外す |
| `S{囲み}`（Visual） | 選択範囲を囲む | `vee` → `S)` |

```text
hello world
"single please"
(unwrap me)
```

- [ ] `hello` を `ysiw"` で `"hello"` にした
- [ ] 2 行目を `cs"'` で `'single please'` にした
- [ ] 3 行目を `ds(` で括弧なしにした

## ヤンク履歴（yanky）

`p` で貼った**直後**に `Ctrl-p` を押すと、1 つ前にコピーしたものに差し替わります（`Ctrl-n` で戻る）。
`<Space>fy` で履歴の一覧からも選べます。

```text
りんご
みかん
ぶどう
```

- [ ] 3 行をそれぞれ `yy` でコピーした（りんご → みかん → ぶどう の順）
- [ ] 下の空行で `p` → `Ctrl-p` を押し、「みかん」「りんご」に差し替わるのを見た

(ここに貼る)

## 増やす・減らす（dial）

`Ctrl-a` / `Ctrl-x` は数値だけでなく、日付・true/false・`&&`/`||`・ADR の状態も切り替えます。

```text
count = 41
enabled = true
date = 2026-09-28
状態: Proposed
if (a && b)
```

- [ ] 各行の値の上で `Ctrl-a` を押して変化を見た
- [ ] `Ctrl-a` を押しすぎたら `Ctrl-x` で戻した

## 名前の形を変える（abolish）

| キー | 変換後 |
|------|--------|
| `crs` | snake_case |
| `crc` | camelCase |
| `crm` | MixedCase |
| `cru` | UPPER_CASE |
| `cr-` | kebab-case |

```text
shippingFee
```

- [ ] `crs` で `shipping_fee`、`cru` で `SHIPPING_FEE`、`crc` で `shippingFee` に戻した

## 揃える・分ける

| キー | 動作 |
|------|------|
| `ga` + 区切り文字 | 揃える（例: 段落を選んで `ga=`） |
| `<Space>cj` | 1 行 ↔ 複数行（オブジェクト・引数・配列） |

```ts
const short = 1;
const muchLongerName = 2;
const x = 3;
const config = { port: 5500, host: "localhost", open: true };
```

- [ ] 上 3 行を `vip` で選んで `ga=` を押し、`=` の位置が揃うのを見た
- [ ] `config` の行の `{` の中で `<Space>cj` を押して複数行にし、もう一度押して 1 行に戻した

## レジスタ（名前付きのクリップボード）

`"a` を前に付けると、レジスタ `a` にコピー・貼り付けできます。`:reg` で中身を一覧。

- [ ] `"ayy` で 1 行をレジスタ a に入れ、別の場所で `"ap` で貼った
- [ ] `:reg` で中身を見た

## 卒業チェック

- [ ] `ci"` と `cs"'` の違いを説明できる
- [ ] 貼り間違えたとき `Ctrl-p` で差し替えるようになった
