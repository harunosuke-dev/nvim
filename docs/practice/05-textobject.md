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

| 打鍵 | どこにカーソルを置くか | 起きること |
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

| 打鍵 | 範囲 |
|---|---|
| `diw` | 単語（word） |
| `daw` | 単語 + 後ろの空白 |
| `dis` | 文（sentence） |
| `dip` | 段落（paragraph） |

**課題** — 2つ目の文の中で `dis`。文だけが消える。

**`ciw` は最も使う。** 単語の上で `ciw` して打ち直す、を体に入れる。

---

## 5. 引数を1つだけ

この設定では **mini.ai** が入っていて、引数を単位として扱える。

```typescript
function send(url: string, body: object, retries: number) {}
```

| 打鍵 | 範囲 |
|---|---|
| `dia` | 引数1つ（**a**rgument） |
| `daa` | 引数1つ + カンマ |

**課題** — `body` の上で `daa`。カンマごと消えて、残りが `(url: string, retries: number)` になれば正解。

`cia` なら引数の中身だけ書き換えられる。

---

## 6. 関数を丸ごと

```lua
local function helper(x)
  return x * 2
end

local function main()
  return helper(21)
end
```

| 打鍵 | 範囲 |
|---|---|
| `dif` | 関数の中身（**f**unction） |
| `daf` | 関数ごと |
| `vaf` | 関数を選ぶ |

**課題** — `helper` の中で `daf`。関数が丸ごと消える。`u` で戻して `dif`。中身だけ消える。

---

## 7. 囲みを操作する（nvim-surround）

**囲みを後から足す・変える・外す。**

```
hello world
```

| 打鍵 | 起きること |
|---|---|
| `ysiw"` | 単語を `"` で囲む（**y**ou **s**urround **i**nner **w**ord） |
| `cs"'` | `"` を `'` に変える（**c**hange **s**urround） |
| `ds'` | `'` を外す（**d**elete **s**urround） |
| `yss(` | 行全体を `(` で囲む |

**課題** — `hello` の上で `ysiw"` → `cs"'` → `ds'` を順に打つ。1周して元に戻る。

タグも扱える。`ysiw<em>` で `<em>hello</em>` になる。

---

## 8. 移動と組み合わせる

テキストオブジェクトは動詞と同じく**掛け算**で効く。

```javascript
const options = { debug: true, level: "info", retries: 3 }
```

| 打鍵 | 起きること |
|---|---|
| `yi{` `p` | 中身をコピーして貼る |
| `vi{` `>` | 中身を選んでインデント |
| `ci"` | 文字列の中を書き換え |
| `di{` `i` | 中身を消してその場で書き始める |

---

## 9. まとめの課題

下のコードを、テキストオブジェクトだけで目標の形にする。**`x` や `dw` を使わずにやる。**

```javascript
function greet(name, title) {
  return "Hello, " + name
}
```

目標:

```javascript
function greet(fullName) {
  return `Hi, ${fullName}`
}
```

<details><summary>手順の例</summary>

```
括弧の中で   ci( fullName Esc
文字列の上で cs"`              " を ` に変える
文字列の中で ci` Hi, ${fullName} Esc
+ 以降で     d$                残りを消す
```

`ci(` は引数を丸ごと、`ci\`` は文字列の中身だけを狙える。

</details>

---

次は [06 コマンドライン](06-cmdline.md)。`:Practice 06` で開く。
