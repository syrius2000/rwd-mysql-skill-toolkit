
# 改善するスキル
security-vulnerability-check
vcd-categorical-analysis

## 制限
.agent
.cursor
両方に同一内容を配置すること。

## 追加・改定する機能

report.htmlの内容をより分かりやすくする、summary.csvの項目を増やす、残差プロットの解釈ガイドを追加する。

残差分析の表は、ソート順がabs_resの降順で、どのセルがモデルから最も乖離しているかが一目でわかるようになっている。
しかし、ggplot2の図には、ソートは必要ない。カテゴリー名の順序は、元のデータの順序を保つことにより両者を比較しやすくする。

Admit Gender Dept pearson_res abs_res cell_label
Admitted Male A 20.243536 20.243536 Admitted:Male:A
Admitted Male B 18.782579 18.782579 Admitted:Male:B
Rejected Female A -13.969668 13.969668 Rejected:Female:A
Rejected Female E 12.793744 12.793744 Rejected:Female:E
Rejected Female B -11.386469 11.386469 Rejected:Female:B
Admitted Male F -11.115380 11.115380 Admitted:Male:F
Rejected Female C 10.806676 10.806676 Rejected:Female:C
Rejected Female F 10.498746 10.498746 Rejected:Female:F
Admitted Female F -8.329490 8.329490 Admitted:Female:F
Admitted Female B -7.817356 7.817356 Admitted:Female:B
Rejected Male C -7.065946 7.065946 Rejected:Male:C
Admitted Male E -7.035848 7.035848 Admitted:Male:E
Admitted Male C -6.299386 6.299386 Admitted:Male:C
Rejected Male F 5.650299 5.650299

## 開発手順

テストを書いてから実装を進める。
レポートにはusbadmissions のデータセットを利用してレポートを作成する。結果を確認して、解釈ガイドを作成する。

worktree利用してもよい。判断に任せる。gitの整理をおねがい。現在状況でいったん保存してから、君の望むままに実施して。
