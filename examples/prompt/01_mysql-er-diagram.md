# 対象スキル
mysql-er-diagram

## 標準プロンプト（コピペ用）
> example/mf.db の BASE TABLE だけを対象に ER 図を出してください。Draw.io XML と PlantUML の両方、辞書 CSV も再生成してください。出力は example/skill_out に保存してください。

## 入出力（example 固定）

- 入力: `example/mf.db`
- 出力:
  - `example/skill_out/mf_dictionary.csv`
  - `example/skill_out/mf_er_{MMDD}_{HHMM}.md`
  - `example/skill_out/mf_er_{MMDD}_{HHMM}.xml`

## 完了チェックリスト

- [ ] `example/skill_out/mf_dictionary.csv` が更新されていること
- [ ] `example/skill_out/mf_er_*.md` (PlantUML記述入り) が生成されていること
- [ ] `example/skill_out/mf_er_*.xml` (Draw.io互換XML) が生成されていること
