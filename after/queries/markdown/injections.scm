; extends

; ```python:hello.py や ```:hello.py のようにファイル名を添える書き方に対応する。
;
; 標準の定義は info_string をそのまま言語名として扱うため、「python:hello.py」
; という言語を探しに行って見つからず、中身が色分けされないまま残る。
;
; code-language! は lua/plugins/treesitter.lua で登録している自作の指示。
; : の前を言語名として使い、空なら拡張子から推定する。
(fenced_code_block
  (info_string) @_info
  (code_fence_content) @injection.content
  (#code-language! @_info))
