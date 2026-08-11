# 08 囲みの操作 — 覚えると書き換えが速くなるプラグイン

> **このファイルは複製です。** やり直すなら `:Practice 08`。
> **ここだけプラグインが要る**（nvim-surround）。ssh 先の素の `vim` では通らない。
> 素の Vim での代わりは最後の節に置いてある。

---

## 1. なぜこれだけプラグインを入れるか

`"hello"` を `'hello'` に変える。素の Vim だと囲みの片方ずつ相手をする。

```
f"x  f"x  i'<Esc>  ...
```

nvim-surround なら **`cs"'` の4打鍵で終わる。** 囲みを1つのまとまりとして
扱えるようになる。**この1点だけで入れる価値がある。**

覚えるのは3つだけ。

|      | 由来                    | すること             |
| ---- | ----------------------- | -------------------- |
| `ys` | **y**ou **s**urround    | 囲みを**足す**       |
| `cs` | **c**hange **s**urround | 囲みを**入れ替える** |
| `ds` | **d**elete **s**urround | 囲みを**外す**       |

---

## 2. `ds` — 外す（一番わかりやすい）

`ds` の後ろに**外したい囲みの記号**を打つ。

```javascript
const message = "hello";
const items = [1, 2, 3];
const wrapped = compute(value);
```

**課題** — 1つずつ試す。毎回 `u` で戻す。**カーソルは囲みの中ならどこでもよい。**

```
"hello" の中で ds"      → hello
[1, 2, 3] の中で ds[    → 1, 2, 3
compute(value) の中で ds(  → computevalue
```

---

## 3. `cs` — 入れ替える

`cs` の後ろに **今の囲み** → **新しい囲み** の順で2つ打つ。

```javascript
const greeting = "hello";
const path = "src/index.js";
const call = compute(value);
```

**課題** — 順に打つ。1周して元に戻る。

| キー            | 結果                      |
| --------------- | ------------------------- |
| `cs"'`          | `"hello"` → `'hello'`     |
| `cs'` + `` ` `` | `'hello'` → `` `hello` `` |
| ``cs` "``       | `` `hello` `` → `"hello"` |

括弧同士も入れ替わる。`compute(value)` の中で `cs)]` を打つと
`compute[value]` になる。

---

## 4. `ys` — 足す（的を指定する）

`ys` だけは**どこを囲むか**を渡す必要がある。テキストオブジェクト（05）が
そのまま使える。

| キー    | すること                             |
| ------- | ------------------------------------ |
| `ysiw"` | **単語**を `"` で囲む                |
| `yss)`  | **行全体**を `(` で囲む（`s` を2回） |
| `ysa"}` | **引用符ごと** `{}` で囲む           |
| `ysi(]` | 括弧の**中身**を `[]` で囲む         |

```javascript
hello world
name
```

**課題** — `hello` の上で `ysiw"` を打つ。`"hello" world` になる。

`u` で戻し、今度は `yss)` を打つ。行全体が `(hello world)` になる。

---

## 5. 開き括弧と閉じ括弧は違う

**ここが最初に引っかかるところ。**

| キー   | 結果                                     |
| ------ | ---------------------------------------- |
| `yss)` | `(hello world)` — **空白なし**           |
| `yss(` | `( hello world )` — **内側に空白が入る** |

**閉じ括弧が「詰める」、開き括弧が「空ける」。** `{}` `[]` も同じ。
迷ったら**閉じ括弧側**を打てばよい。

**課題** — 同じ行で `yss)` と `yss(` を打ち比べる。毎回 `u` で戻す。

---

## 6. タグ — `<` ではなく `t`

**`ysiw<em>` は動かない。** `<` はただの囲み文字として扱われ、
`< hello >` になる。タグは `t` を使い、**聞かれてから名前を打つ。**

```html
hello world <em>emphasis</em>
```

**課題** — `hello` の上で `ysiwt` を打つ。`Enter the HTML tag:` と聞かれるので
`em` と打って `Enter`。`<em>hello</em>` になる。

| キー                     | すること                       |
| ------------------------ | ------------------------------ |
| `ysiwt` → `em` `Enter`   | 単語を `<em>` で囲む           |
| `cst` → `strong` `Enter` | 今のタグを `<strong>` に変える |
| `dst`                    | タグを外して中身だけ残す       |

`cst` はカーソルがタグの**中**にあれば効く。`<em>emphasis</em>` の
`emphasis` の上で `cst` → `b` `Enter` で `<b>emphasis</b>`。

**属性ごと打ってもよい。** `ysiwt` → `div class="box"` `Enter` で
`<div class="box">hello</div>`。閉じタグには名前だけが入る。

---

## 7. 関数呼び出し — `f`

`f` は関数で包む。これも聞かれてから名前を打つ。

```javascript
value;
console.log(result);
```

**課題** — `value` の上で `ysiwf` を打ち、`String` と打って `Enter`。
`String(value)` になる。

| キー                       | すること                     |
| -------------------------- | ---------------------------- |
| `ysiwf` → `String` `Enter` | `value` → `String(value)`    |
| `csf` → `warn` `Enter`     | `console.log(x)` → `warn(x)` |
| `dsf`                      | `console.log(x)` → `x`       |

**`dsf` は「この関数呼び出しを剥がす」。** デバッグの `console.log()` を
外す時にそのまま効く。

---

## 8. 選んでから囲む

範囲が変則的で的を言い表せない時は、ビジュアルで選んでから `S`。

```javascript
first second third
```

**課題** — `viw` で単語を選び、`S]` を打つ。`[first]` になる。

`V`（行選択）から `S)` を打つと**改行して**囲む。

```
(
  first second third
)
```

ノーマルモードの `yS` も同じく改行する。`ySiw)` で単語が3行になる。
**JSX や関数の中身を丸ごと包み直す時に効く。**

---

## 9. `.` での繰り返しには注意

`.` は繰り返せるが、**囲みを足した分だけ文字がずれる。**

```
aa bb cc
```

`ysiw"` の後で `2w.` を打つと `"aa""" bb cc` になる。`w` が挿入された `"` を
1語と数えるため、狙いから外れる。

**次の単語へは移動を目で確かめてから打つ。** `f` で行き先を指定するか、
素直に打ち直す方が速い。

---

## 10. 素の Vim ではどうするか

ssh 先にこのプラグインは無い。**同じことを標準機能でやる形も知っておく。**

| したいこと            | nvim-surround | 素の Vim                              |
| --------------------- | ------------- | ------------------------------------- |
| `"hello"` → `'hello'` | `cs"'`        | `ci"` で中身を取り直すか `f"r'` を2回 |
| `"hello"` → `hello`   | `ds"`         | `di"` して `hi`、または `f"x` を2回   |
| 単語を `"` で囲む     | `ysiw"`       | `ciw` → `"` → `Ctrl+r` `"` → `"` → `Esc`                   |

`<C-r>"` は挿入モードで**直前に消したもの**を貼る書き方。`ciw` で単語を消して
挿入モードに入り、`"` を打ち、消した単語を貼り、`"` を打つ。

**打鍵数が3倍になる。** これが nvim-surround を入れる理由そのもの。

---

## 11. まとめの課題

下のコードを、囲みの操作だけで直す。

```javascript
const label = "user name";
const node = <span>text</span>;
console.log(payload);
```

目標:

1. `"user name"` を `` ` `` （テンプレートリテラル）に変える
2. `<span>` を `<strong>` に変える
3. `console.log(payload)` から呼び出しを外して `payload` だけにする
4. 残った `payload` を `String()` で包む

<details><summary>手順</summary>

```
1行目の user name の中で   cs"`
2行目の text の中で        cst  → strong Enter
3行目の payload の中で     dsf
そのまま payload の上で    ysiwf → String Enter
```

`dsf` の後、カーソルは `payload` の上に残るのでそのまま `ysiwf` へ続けられる。

</details>

---

一周したら [practice.md](../practice.md) の一覧に戻る。
**囲みの操作は使う場面が多い。** `cs` と `ds` の2つだけでも先に実戦へ持ち込むと、
`ys` は後から自然に付いてくる。
