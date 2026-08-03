; extends

; 数式（$...$ と $$...$$）に色を付ける。
;
; 標準の定義は latex_block に何も割り当てておらず、本文と同じ色で並ぶ。
; 数式が地の文に埋もれて境目が分からないため、専用の色を当てる。
;
; 区切りの $ は中身と分けて、どこからどこまでが数式かを示す。
; 後に書いた定義が優先されるので、区切りの指定を後ろに置く。
(latex_block) @markup.math

(latex_span_delimiter) @markup.math.delimiter
