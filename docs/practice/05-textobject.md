# 05 テキストオブジェクト — 構造で範囲を指定する

> **このファイルは複製です。** やり直すなら `:Practice 05`。
> **ここが Vim を使う最大の理由。** 時間をかけてよい。

---

## 1. 考え方

「ここからここまで」ではなく「**この括弧の中**」と言える。

```
d  i  (      delete inside ( )     括弧の中身を消す
c  a  "      change around " "     引用符ごと書き換える
```

| | 由来 | 範囲 |
|---|---|---|
| `i` | **i**nside | 中身だけ |
| `a` | **a**round | 囲みの記号を含む |

**カーソルが範囲のどこにあってもよい。** ここが「選んでから消す」との決定的な違い。

---

## 2. `di{` を打つ

```lua
local config = {
  width = 80,
  height = 24,
  wrap = false,
}
```

**課題** — `width` の行のどこでもよいのでカーソルを置き、`di{` を打つ。中身だけ消えて `{}` が残れば正解。

`u` で戻し、今度は `da{` を打つ。**括弧ごと**消える。違いを目で見る。

もう一度 `u` で戻し、`ci{` を打つ。中身が消えて挿入モードに入る。

---

## 3. 括弧・引用符・タグ

```javascript
const result = compute(first, "second value", [1, 2, 3])
```

**課題** — 次を1つずつ試す。毎回 `u` で戻す。

| キー | どこにカーソルを置くか | 起きること |
|---|---|---|
| `di(` | 括弧の中ならどこでも | 引数が全部消える |
| `ci"` | `second value` の中 | 文字列の中身を書き換え |
| `da"` | 同上 | 引用符ごと消える |
| `di[` | 配列の中 | `1, 2, 3` が消える |
| `ci(` | 括弧の中 | 引数を書き直す |

HTML なら `dit`（tag の中）と `dat` が効く。

```html
<div class="box"><span>text here</span></div>
```

**課題** — `text here` の上で `dit`。次に `u` して `dat`。

---

## 4. 単語・文・段落

```
This is the first sentence. This is the second one. And a third.

This is another paragraph with several words in it.
```

| キー | 範囲 |
|---|---|
| `diw` | 単語（word） |
| `daw` | 単語 + 後ろの空白 |
| `dis` | 文（sentence） |
| `dip` | 段落（paragraph） |

**課題** — 2つ目の文の中で `dis`。文だけが消える。

**`ciw` は最も使う。** 単語の上で `ciw` して打ち直す、を体に入れる。

---

## 5. 移動と組み合わせる

テキストオブジェクトは動詞と同じく**掛け算**で効く。

```javascript
const options = { debug: true, level: "info", retries: 3 }
```

| キー | 起きること |
|---|---|
| `yi{` `p` | 中身をコピーして貼る |
| `vi{` `>` | 中身を選んでインデント |
| `ci"` | 文字列の中を書き換え |
| `di{` `i` | 中身を消してその場で書き始める |

---

## 6. まとめの課題

下のコードを、テキストオブジェクトだけで目標の形にする。
**`x` や `dw` を使わずにやる。**

```javascript
function greet(name, title) {
  return "Hello, " + name;
}
```

目標:

```javascript
function greet(fullName) {
  return "Hi, " + fullName;
}
```

<details><summary>手順の例</summary>

```
括弧の中で       ci( fullName Esc
"Hello, " の中で ci" Hi,  Esc
name の上で      ciw fullName Esc
```

`ci(` は引数を丸ごと、`ci"` は文字列の中身だけ、`ciw` は単語だけを狙える。
**どれもカーソルが範囲内にあればよく、先頭へ移動する必要が無い。**

</details>

---

## 7. この設定で足してあるもの

素の Vim のテキストオブジェクトはここまで。**プラグインで単位を増やせる。**

| キー | 範囲 | 出どころ |
|---|---|---|
| `dia` `daa` | 引数1つ（`daa` はカンマごと） | mini.ai |
| `dif` `daf` | 関数の中身 / 関数ごと | treesitter |
| `saiw)` `sr"'` `sd(` | 囲みを足す・変える・外す | mini.surround |

**引数と関数は [07](07-editor.md)、囲みは [08](08-surround.md) で扱う。**
どれも ssh 先の素の `vim` では通らない。

---

次は [06 コマンドライン](06-cmdline.md)。`:Practice 06` で開く。
