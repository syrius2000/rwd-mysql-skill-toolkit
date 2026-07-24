# implementation_plan_008_0724 レビュー結果（別AI向け詳細）

created: 2026-07-24 23:08 (JST)
author: AI Agent (Composer)

## 0. この文書の使い方

- **対象計画**: `docs/Artifacts/implementation_plan_008_0724.md`
- **関連完了報告**: `docs/Artifacts/walkthrough_001_0725.md`
- **読者**: 別AIエージェント。**最新の実装評価・フォロー点検は必ず §13 を読むこと。**
- **文書の層**:
  | 節 | 時点 | 内容 |
  | --- | --- | --- |
  | §1–11 | 計画レビュー初回 | 差し戻し根拠（歴史） |
  | §12 | 計画改訂第2版 | 条件付き承認可 |
  | **§13（最新）** | 実装後＋フォロー対応点検 | ギャップ評価 → 対応コメント照合 → 残課題 |
- **判定サマリ（最新は §13.1）**: コア実装は達成。フォローで主要ギャップはほぼ解消。R相互運用 Spearman は未実施。解釈ガイドの出力仕様と L2=`uv sync` 表記に軽微な不一致あり。

### 絶対パス一覧（主要）

| 役割 | 絶対パス |
| --- | --- |
| 本レビュー文書 | `/Users/myamaguchi/Programing/rwd-mysql-skill-toolkit/docs/Artifacts/review_implementation_plan_008_0724.md` |
| レビュー対象計画 | `/Users/myamaguchi/Programing/rwd-mysql-skill-toolkit/docs/Artifacts/implementation_plan_008_0724.md` |
| リポジトリルート | `/Users/myamaguchi/Programing/rwd-mysql-skill-toolkit` |
| エージェント規則 | `/Users/myamaguchi/Programing/rwd-mysql-skill-toolkit/AGENTS.md` |
| ドキュメント索引 | `/Users/myamaguchi/Programing/rwd-mysql-skill-toolkit/docs/README.md` |
| Python Skill ルート | `/Users/myamaguchi/Programing/rwd-mysql-skill-toolkit/.agent/skills/anomaly-detection/` |
| R Skill 正本（ホーム配下・リポジトリ外） | `/Users/myamaguchi/.agents/skills/r-anomary-detection/` |
| 関連旧計画（VACCINEスモーク） | `/Users/myamaguchi/Programing/rwd-mysql-skill-toolkit/docs/Artifacts/implementation_plan_002_0702_anomaly_vaccine_smoke.md` |
| JSONL解釈ガイド | `/Users/myamaguchi/Programing/rwd-mysql-skill-toolkit/docs/Reference/anomaly-detection/anomaly_results_interpretation.md` |

相対パスはリポジトリルート基準。R Skill のみホーム配下の絶対パスを使う。

---

## 1. 計画の要約（レビュー対象が主張していること）

計画 `implementation_plan_008_0724.md` のゴールは次の3点の同時達成である。

1. ローカル Python Skill `anomaly-detection` に、R Skill `r-anomary-detection` の高度手法（MCD / STL / PSI / Score Fusion）を取り込む。
2. Python 環境構築を `pip`/`venv` から **`uv` 全面移行**する。
3. 初学者向けに `setup_env.py` / ヘルスチェック / `uv run` による自動診断・ワンコマンド構築を入れる。

提案コンポーネント:

- Component 1: `scripts/setup_env.py`, Makefile/`uv`化, `pyproject.toml` 依存追加
- Component 2: `mcd_detector.py`, `stl_detector.py`, `psi_detector.py`（新規）
- Component 3: `fusion.py` 改修、共通 JSONL schema、SKILL.md/README 改訂

検証:

- 未構築状態から `setup_env.py` → 「3秒以内」に `.venv` 同期
- 合成CSVで `infer.py` → JSONL に `fused_score`, `mcd_score`, `stl_score`, `psi_score`

---

## 2. 総合判定

| 観点 | 判定 | コメント |
| --- | --- | --- |
| 方針の妥当性 | 良い | R機能のPython移植 + `uv`化はリポジトリ責務と整合 |
| 現行コードとの整合 | **要修正** | 存在しないファイルを MODIFY している |
| 「R完全互換」主張 | **過大** | アルゴリズム・出力粒度が一致しない |
| スキーマ設計 | **不足** | 既存 schema との関係が未定義 |
| 検証計画 | **不足** | 非現実的SLA、単体テスト欠落、入力契約欠落 |
| スコープ制御 | **不足** | `uv`・検出器・schema・Windows を一括 |
| 文書フォーマット | **軽微** | author 表記が Artifacts ルールと不一致 |
| 実装着手 | **禁止** | ユーザー明示承認まで実装しない（AGENTS.md / plan-artifacts） |

**推奨アクション**: 本レビューのブロッカーを反映した改訂版計画を作り、再レビュー → ユーザー承認後に実装。

---

## 3. 現行コードベースの事実（計画改訂の前提）

別AIは「計画に書いてあるパスが正しい」と仮定せず、以下を正とする。

### 3.1 Python Skill の実在ファイル構成（`.venv` 除外）

ルート:

```text
.agent/skills/anomaly-detection/
├── SKILL.md
├── README.md
├── skill.yaml
├── Makefile                          # 現状 pip / pytest 直接
├── pyproject.toml                    # setuptools、statsmodels 未記載
├── configs/
│   ├── default.yaml
│   ├── small-scale.yaml
│   └── large-scale.yaml
├── scripts/
│   ├── infer.py
│   ├── train.py
│   ├── generate_synth.py
│   └── benchmark.py
│   # setup_env.py / check_health.py は未存在
├── src/anomaly_detection/
│   ├── pipeline.py                   # Score Fusion はここ（fusion.py は無い）
│   ├── detectors.py                  # EnsembleDetector 単一モジュール（detectors/ パッケージは無い）
│   ├── rules.py
│   ├── features.py
│   ├── schemas.py
│   ├── cli.py
│   ├── io.py
│   ├── audit.py
│   ├── explain.py
│   ├── config.py
│   ├── api.py
│   └── __init__.py
├── docs/
│   ├── schemas/
│   │   ├── input.schema.json         # 既存
│   │   └── output.schema.json        # 既存
│   ├── architecture.md
│   ├── api_reference.md
│   ├── operations.md
│   ├── test_plan.md
│   └── ...
├── tests/
│   ├── test_pipeline.py
│   ├── test_rules.py
│   └── test_schemas.py
└── .github/workflows/ci.yml
```

絶対パス例:

- `/Users/myamaguchi/Programing/rwd-mysql-skill-toolkit/.agent/skills/anomaly-detection/src/anomaly_detection/pipeline.py`
- `/Users/myamaguchi/Programing/rwd-mysql-skill-toolkit/.agent/skills/anomaly-detection/src/anomaly_detection/detectors.py`
- `/Users/myamaguchi/Programing/rwd-mysql-skill-toolkit/.agent/skills/anomaly-detection/pyproject.toml`
- `/Users/myamaguchi/Programing/rwd-mysql-skill-toolkit/.agent/skills/anomaly-detection/Makefile`
- `/Users/myamaguchi/Programing/rwd-mysql-skill-toolkit/.agent/skills/anomaly-detection/configs/default.yaml`
- `/Users/myamaguchi/Programing/rwd-mysql-skill-toolkit/.agent/skills/anomaly-detection/docs/schemas/output.schema.json`

### 3.2 Score Fusion の現状（Python）

ファイル: `.agent/skills/anomaly-detection/src/anomaly_detection/pipeline.py`

- L35–41: `config["score_fusion"]` の重みで `rule_score` / `robust` / `iforest` / `lof` を線形結合し `.clip(0, 1)`。
- **`fusion.py` は存在しない。** 計画の `MODIFY .../fusion.py` は誤り。
- 出力キーは `score` / `model_contributions`（計画検証の `fused_score` というトップレベルキーとは名前が異なる）。

設定: `.agent/skills/anomaly-detection/configs/default.yaml` L50–53

```yaml
score_fusion:
  rule_weight: 0.40
  robust_weight: 0.15
  iforest_weight: 0.25
  lof_weight: 0.20
```

合計 1.0。MCD/STL/PSI 追加時は **重み再配分と後方互換方針**が必須。

### 3.3 検出器の現状（Python）

ファイル: `.agent/skills/anomaly-detection/src/anomaly_detection/detectors.py`

- `EnsembleDetector` が Isolation Forest + LOF のみ。
- `_scale01`（L12–19）で手法内 min-max 正規化済みスコアを返す。
- **`detectors/` ディレクトリは無い。** 計画の `detectors/mcd_detector.py` 等は **新規パッケージ分割**か **既存モジュール拡張**かを明示する必要がある。

### 3.4 依存関係の現状

ファイル: `.agent/skills/anomaly-detection/pyproject.toml`

- 依存: `numpy`, `pandas`, `pydantic`, `PyYAML`, `scikit-learn`
- **未記載**: `statsmodels`, `scipy`（計画は STL 用に statsmodels を追加する想定で正しい）
- build-system: setuptools
- Makefile: `python -m pip install -e '.[dev]'`（`uv` 未使用）

補足: ローカルに `.venv/` が既にあり、site-packages に `uv_cache.json` / `uv_build.json` 痕跡がある。つまり **開発マシンでは uv 利用の痕跡があるが、リポジトリの Makefile/docs は依然 pip 前提**。計画は「現状からの移行差分」を書くべき。

### 3.5 既存スキーマ

- `.agent/skills/anomaly-detection/docs/schemas/input.schema.json`
- `.agent/skills/anomaly-detection/docs/schemas/output.schema.json`
  - 必須: `results`, `summary`
  - 各 result: `record_id`, `score`, `label`（enum: normal/warning/critical）
  - 任意: `triggered_rules`, `model_contributions`, `explanation`

計画の `NEW .../unified_anomaly_schema.json` は、上記との **置換 / 拡張 / 別系統** を決めないと破壊的変更になる。

解釈ガイド（リポジトリ共通）:

- `docs/Reference/anomaly-detection/anomaly_results_interpretation.md`

### 3.6 R Skill 側の正本（取り込み元）

ルート: `/Users/myamaguchi/.agents/skills/r-anomary-detection/`

重要ファイル:

| 内容 | パス |
| --- | --- |
| Skill 契約 | `/Users/myamaguchi/.agents/skills/r-anomary-detection/SKILL.md` |
| 実装本体 | `/Users/myamaguchi/.agents/skills/r-anomary-detection/scripts/utils.R` |
| Fusion | 同 `utils.R` の `calculate_fused_anomaly_score`（おおよそ L272–314） |
| STL | 同 `utils.R` の `detect_ts_stl`（おおよそ L320–336） |
| PSI | 同 `utils.R` の `calculate_psi`（おおよそ L357–389） |
| KS（分布比較） | 同 `utils.R` の `compare_distribution_shift`（おおよそ L338–355） |
| MCD | 同 `utils.R` の `detect_multivariate_mcd`（おおよそ L120付近） |
| Fusion テスト | `/Users/myamaguchi/.agents/skills/r-anomary-detection/test/testthat/test_fusion.R` |
| PSI テスト | `/Users/myamaguchi/.agents/skills/r-anomary-detection/test/testthat/test_psi.R` |

**重要**: R の PSI は **baseline vs current グループ比較のスカラー**（`psi_value`, `shift_level`）を返す。行ごとの `psi_score` ではない。計画の検証項目「JSONL に `psi_score`」は設計決定が必要。

KS は R に `compare_distribution_shift` として存在するが、計画比較表では「PSI / KS検定モジュール」と書きつつ Component 2 に KS ファイルが無い。

---

## 4. ブロッカー指摘（承認前に必ず直す）

### B1. 存在しないファイルを MODIFY している

| 計画の記述 | 問題 | 改訂案 |
| --- | --- | --- |
| `MODIFY .../fusion.py` | ファイル無し。融合は `pipeline.py` | `pipeline.py` を MODIFY、または **NEW `fusion.py` + pipeline から呼ぶ** と明記 |
| `NEW .../detectors/mcd_detector.py` 等 | `detectors/` パッケージ無し | (A) `detectors.py` を拡張、(B) `detectors/` に分割して `EnsembleDetector` を移行、のどちらかを選ぶ |
| `NEW .../unified_anomaly_schema.json` | 既存 input/output schema と関係不明 | 既存を version bump するか、unified を追加契約にするかを決める |

### B2. 「R版と完全互換の Score Fusion」は現状の定義では成立しない

比較:

| 項目 | Python 現状 | R 現状 |
| --- | --- | --- |
| 正規化 | 検出器側 `_scale01` 後に加重 | Fusion 内で再度 `normalize_01` |
| 重み正規化 | 固定重みの和（想定 1.0） | 有効重みで割って再正規化（`weight_sum`） |
| 列名 | `iforest` / `lof` / `rule_score` / `robust_mad` | `anomaly_score` / `lof_score` / `rule_anomaly_score` |
| 閾値ラベル | warning/critical の2段 | `is_fused_anomaly`（単一 threshold） |
| 出力キー | `score` | `fused_anomaly_score` |

「完全相互互換」を残すなら、成功条件を次のいずれか（または複数）に落とす:

1. **スキーマ互換**: 必須キー集合が一致（名前マッピング表付き）
2. **アルゴリズム互換**: 同一正規化・同一重み適用手順を文書化して共有テストベクターで一致
3. **順位互換**: 同一合成データで fused 順位の Spearman 相関が閾値以上

数値完全一致を要求するなら、正規化の二重適用有無・NA処理・clip の有無まで仕様化する。

### B3. PSI / STL / KS の入出力契約が欠落

#### PSI

- R: グループ間スカラー（バッチ指標）
- 計画検証: 行単位 `psi_score`
- 改訂で決めること:
  - JSONL のどこに置くか（`summary` 側 vs 各行の同一値複製 vs 別成果物）
  - 入力に必要な `group_col` / `baseline_group` / `current_group`（config キー）
  - 合成データの生成方法（`generate_synth.py` 改修要否）

#### STL

- R: `time_col`, `value_col`, `frequency` 必須。欠損は `zoo::na.approx`
- EDC 合成CSVはレコード横断の不規則時系列になりがち
- 改訂で決めること:
  - 集約粒度（site×日、subject×visit 等）
  - `frequency` の既定と短系列時のスキップ条件
  - Python 実装を `statsmodels.tsa.seasonal.STL` にする場合の依存と失敗時挙動

#### KS

- 比較表に「PSI / KS」とあるが NEW ファイル無し
- R には `compare_distribution_shift` がある
- 改訂で: KS をスコープイン（ファイル追加）かスコープアウト（比較表から削除）を明示

### B4. 検証計画の非現実性・不足

問題点:

1. 「3秒以内に `.venv` 作成＋依存同期」は cold cache で scipy/sklearn/statsmodels を入れると非現実的。合格条件から削除するか「warm cache」前提を書く。
2. 検出器単体テストが無い（現状 tests は pipeline/rules/schemas のみ）。
3. 既存出力互換テストが無い（`score` vs `fused_score`、schema version）。
4. `make setup` と `python3 scripts/setup_env.py` の入口が二系統。どちらを正とするか。
5. CI（`.agent/skills/anomaly-detection/.github/workflows/ci.yml`）への `uv` 反映が計画に無い。

### B5. Component 一覧と本文の不整合

- §3 で `scripts/check_health.py` を説明するが、§4 Component 1 の成果物に載っていない。
- Windows 対応を書くが、`AGENTS.md` は macOS / Ubuntu 優先。Windows は非目標にするか明示承認対象にする。

---

## 5. 中程度の指摘（改訂推奨）

### M1. スコープが大きすぎる

推奨フェーズ分割:

| Phase | 内容 | 完了条件（例） |
| --- | --- | --- |
| Phase 1 | `uv` 移行（pyproject / uv.lock / Makefile / README / CI） | `uv sync` + `uv run pytest` 緑 |
| Phase 2 | MCD 追加 + config 重み + 単体テスト | MCD 単体 + pipeline 回帰 |
| Phase 3 | STL / PSI（+任意 KS）+ 入力契約 + synth データ | 各手法の契約テスト |
| Phase 4 | Fusion 共通仕様 + schema version bump + 解釈ガイド更新 | スキーマ検証 + 相互運用メモ |

一括実装を強行する場合でも、計画上は依存順序とロールバック方針を書く。

### M2. 設定・重み設計が無い

`configs/default.yaml`（および small/large）に以下を追加する設計が必要:

- `mcd.enabled`, パラメータ（support_fraction 等）
- `stl.enabled`, `time_col`, `value_col`, `frequency`, `sigma`
- `psi.enabled`, `group_col`, `baseline_group`, `current_group`, `n_bins`
- `score_fusion` の新重みと合計制約
- 無効手法の重み再配分ルール（R の `weight_sum` 方式に寄せるか）

### M3. 成果物配置ルール（AGENTS.md）との接続不足

リポジトリ規則:

- Skill 成果物は原則 `skill_out/`、再実行は `run_<id>/` 隔離
- Python Skill の CLI は既に `--output-root` / `run_<id>` を持つ（`SKILL.md` 記載）

計画の検証が `outputs/anomaly_results.jsonl`（古い Makefile `infer` ターゲット）に寄っている。現行推奨経路との整合を取る。

### M4. 関連計画との関係が未記載

- `docs/Artifacts/implementation_plan_002_0702_anomaly_vaccine_smoke.md`  
  VACCINE DB スモーク。008 実装後に再実行が必要か、独立か。
- R 側にも同日系の強化計画がある（例: `/Users/myamaguchi/.agents/skills/r-anomary-detection/docs/Artifacts/`）。  
  **008 は Python 側のみ変更**と明記し、R 正本を壊さないこと。

### M5. 「AI ガッチリ自動修復」の実体が曖昧

現状計画は次が混在:

- インストール案内メッセージ
- `uv` 再実行
- 「対話的解決ガイド」

改訂でレベルを定義する例:

- L0: 診断のみ（終了コード非0 + 原因コード）
- L1: 案内文（手動コマンド提示）
- L2: 安全な自動再試行（`uv sync` 再実行まで。システム改変はしない）

`curl | sh` による uv インストール自動実行はセキュリティ上、**案内のみ**を推奨（自動実行するならユーザー確認フラグ必須）。

### M6. 文書フォーマット

Artifacts ルール（ユーザー Cursor rule `plan-artifacts`）:

1. `# タイトル`
2. `created: YYYY-MM-DD HH:MM (JST)`
3. `author: AI Agent (LLM名)`
4. 空行
5. 本文

対象計画の author は `Antigravity (Gemini 3.6 Flash)`。改訂時に `AI Agent (...)` 形式へ揃えるのが望ましい。

ファイル名 `implementation_plan_008_0724.md` 自体は命名規約に合致。

---

## 6. 良い点（維持すべき）

1. R/Python 比較表でギャップが可視化されている。
2. 環境構築フローの Mermaid は初学者・エージェント双方に有用。
3. Component 分割の骨格は読みやすい。
4. `statsmodels` / MCD(`MinCovDet`) / PSI を Python に足す方向性は、R Skill の手法早見表と整合。
5. リポジトリ内ローカル管理 Skill 一覧（`AGENTS.md`）に `anomaly-detection` が含まれており、ここを強化する判断は正しい。R 汎用 Skill をリポジトリに複製しない方針とも矛盾しない（「取り込み」であり追跡コピーではない）。

---

## 7. 計画記載パス vs 推奨パス対応表

| 計画のパス | 実在? | 推奨する扱い |
| --- | --- | --- |
| `.agent/skills/anomaly-detection/scripts/setup_env.py` | 未作成 | NEW で妥当。絶対パスはリポジトリ内相対で可 |
| `.agent/skills/anomaly-detection/scripts/check_health.py` | 未作成・Component漏れ | NEW として Component 1 に追加 |
| `.agent/skills/anomaly-detection/Makefile` | 実在 | MODIFY 妥当 |
| `.agent/skills/anomaly-detection/pyproject.toml` | 実在 | MODIFY 妥当。`uv.lock` 追加も明記 |
| `.../detectors/mcd_detector.py` | 親ディレクトリ未実在 | 分割方針を明記してから NEW |
| `.../detectors/stl_detector.py` | 同上 | 同上 |
| `.../detectors/psi_detector.py` | 同上 | 同上。出力粒度を設計 |
| `.../fusion.py` | **非実在** | NEW+配線、または `pipeline.py` MODIFY |
| `.../docs/schemas/unified_anomaly_schema.json` | 未作成 | 既存 schema との関係を先に定義 |
| `.../SKILL.md`, `README.md` | 実在 | MODIFY 妥当 |
| R: `~/.agents/skills/r-anomary-detection/` | 実在（リポジトリ外） | 参照のみ。008 で改変しないことを明記 |

---

## 8. 改訂チェックリスト（別AIが計画を直すときの ToDo）

計画文書側のみ。実装は承認後。

- [ ] `fusion.py` 記述を現状に合わせて修正（MODIFY pipeline / NEW fusion を選択）
- [ ] `detectors/` 分割か `detectors.py` 拡張かを選択し、移行手順を1段落で書く
- [ ] 既存 `input.schema.json` / `output.schema.json` との関係と version 方針を書く
- [ ] 「完全互換」を削除または成功条件付きの相互運用に言い換える
- [ ] PSI / STL の入力契約・出力粒度・スキップ条件を書く
- [ ] KS をスコープイン/アウト明示
- [ ] `check_health.py` を成果物一覧に追加
- [ ] Windows を非目標にするか、対応範囲を限定
- [ ] 「3秒以内」を削除し、現実的な検証手順に置換
- [ ] 検出器単体テスト・回帰・schema 互換テストを Verification に追加
- [ ] `configs/*.yaml` の変更点を Component に追加
- [ ] Phase 分割または依存順序を追加
- [ ] 非目標 / リスク / 実行ゲート（承認まで実装しない）を追加
- [ ] `implementation_plan_002` との関係を1節追加
- [ ] author 表記を `AI Agent (...)` に揃える
- [ ] CI（`.github/workflows/ci.yml`）の `uv` 化要否を記載
- [ ] 出力パスを現行 `skill_out/.../run_<id>/` 推奨に合わせる

---

## 9. 承認判断ガイド（人間 / 次エージェント向け）

| 状態 | 判断 |
| --- | --- |
| 現状の `implementation_plan_008_0724.md` のまま | **承認しない** |
| 上記ブロッカー B1–B5 を改訂反映し再レビュー合格 | 承認候補 |
| ユーザーが「承認します」「実行して」と明示 | その時点で実装開始可 |

実装時の注意（承認後）:

- 無関係な既存変更（例: `.gitignore` の別差分）をコミットに混ぜない
- DB 更新系は別件。008 は Skill 内 Python が主
- PHI/PII・秘密情報を成果物に出さない（既存 Skill 方針を維持）

---

## 10. 参照リンク（相対・リポジトリ内）

- 対象計画: [implementation_plan_008_0724.md](./implementation_plan_008_0724.md)
- 本レビュー: [review_implementation_plan_008_0724.md](./review_implementation_plan_008_0724.md)
- 関連計画: [implementation_plan_002_0702_anomaly_vaccine_smoke.md](./implementation_plan_002_0702_anomaly_vaccine_smoke.md)
- 解釈ガイド: [../Reference/anomaly-detection/anomaly_results_interpretation.md](../Reference/anomaly-detection/anomaly_results_interpretation.md)
- エージェント規則: [../../AGENTS.md](../../AGENTS.md)
- Python Skill: [../../.agent/skills/anomaly-detection/SKILL.md](../../.agent/skills/anomaly-detection/SKILL.md)
- Python pipeline: [../../.agent/skills/anomaly-detection/src/anomaly_detection/pipeline.py](../../.agent/skills/anomaly-detection/src/anomaly_detection/pipeline.py)
- Python detectors: [../../.agent/skills/anomaly-detection/src/anomaly_detection/detectors.py](../../.agent/skills/anomaly-detection/src/anomaly_detection/detectors.py)
- 出力 schema: [../../.agent/skills/anomaly-detection/docs/schemas/output.schema.json](../../.agent/skills/anomaly-detection/docs/schemas/output.schema.json)

R Skill（リポジトリ外・絶対パス）:

- `file:///Users/myamaguchi/.agents/skills/r-anomary-detection/SKILL.md`
- `file:///Users/myamaguchi/.agents/skills/r-anomary-detection/scripts/utils.R`

---

## 11. レビューメタ情報（初回）

| 項目 | 値 |
| --- | --- |
| レビュー日 | 2026-07-24 (JST) |
| レビュアー | AI Agent (Composer) |
| 対象リビジョン状況 | `implementation_plan_008_0724.md` は未追跡（git status 上 `??`）想定。実装コード未変更レビュー |
| 次の成果物（推奨） | 改訂版 `implementation_plan_008_0724.md`（同一ファイル更新可）または `implementation_plan_009_*.md` |
| 実装 | 未着手・承認待ち |

---

## 12. 再レビュー結果（改訂第2版に対する追記）

> **別AIへの案内**: 本節は **2026-07-24 23:15 (JST) の計画再レビュー**（改訂第2版向け）。実装後の最新判定は **§13**。初回の差し戻し根拠は §1–11。

### 12.1 再レビューメタ

| 項目 | 値 |
| --- | --- |
| 再レビュー日時 | 2026-07-24 23:15 (JST) |
| レビュアー | AI Agent (Composer) |
| 対象文書 | `/Users/myamaguchi/Programing/rwd-mysql-skill-toolkit/docs/Artifacts/implementation_plan_008_0724.md` |
| 対象版 | 改訂第2版（`created: 2026-07-24 23:15 (JST)` / author: `AI Agent (Antigravity Gemini 3.6 Flash)`） |
| 参照した初回レビュー | 本ファイル §1–11、特にブロッカー B1–B5（§4） |
| 実装 | **未着手**。ユーザーの明示承認までコード変更禁止 |

### 12.2 総合判定（最新）

| 観点 | 初回 | 再レビュー | コメント |
| --- | --- | --- | --- |
| 方針の妥当性 | 良い | 良い | 維持 |
| 現行コードとの整合 | 要修正 | **解消** | `fusion.py` NEW、`detectors/` パッケージ化、`pipeline.py` 配線が実態と一致 |
| 「R完全互換」主張 | 過大 | **解消** | Spearman / 正規化手順 / フィールドマッピングに再定義 |
| スキーマ設計 | 不足 | **概ね解消** | 既存 `output.schema.json` の v0.2.0 拡張互換。version フィールド現状非存在は §12.4 参照 |
| 検証計画 | 不足 | **大幅改善** | 3秒SLA削除、単体テスト追加。Spearman が Verification 未反映（残） |
| スコープ制御 | 不足 | **解消** | Phase 1–4 分割 |
| PSI/STL 入力契約 | （初回B3） | **一部残** | summary 配置は良いが config キー不足 |
| 文書フォーマット | 軽微 | **解消寄り** | `AI Agent (...)` 形式 |
| **承認判断** | 承認しない | **条件付き承認可** | §12.4 の軽微追記後が望ましい。追記なしでも Phase 1 限定承認は許容しうる |

**一文判定**: 前回差し戻し理由は概ね解消。残るのはブロッカー級ではなく追記級。実装は依然としてユーザー承認待ち。

### 12.3 初回ブロッカー B1–B5 の解消確認

| ID | 初回指摘要約 | 改訂第2版での扱い | 結果 |
| --- | --- | --- | --- |
| B1 | 存在しない `fusion.py` を MODIFY / `detectors/` 未実在 / schema 関係不明 | NEW `fusion.py` + `pipeline.py` MODIFY。`detectors/` パッケージ化と `detectors.py` 移行。既存 schema を v0.2.0 拡張 | **解消** |
| B2 | 「完全互換」過大 | §2 NOTE で相互運用を ①0-1正規化手順 ②フィールドマッピング ③Spearman と定義 | **解消**（ただし検証§への落とし込みは §12.4-R3） |
| B3 | PSI/STL/KS 入出力契約欠落 | PSI→`summary.psi_metrics`、STL 不規則時スキップ、KS を `psi.py` に同居 | **部分解消**（config キー・synth 改修が不足） |
| B4 | 3秒SLA・単体テスト欠落 | SLA削除、`test_detectors_*.py` / `test_fusion.py`、`skill_out/.../run_<id>/` | **解消**（Spearman テスト未記載は残） |
| B5 | `check_health.py` 漏れ・Windows 曖昧 | Component 1 に NEW。Windows 記述は削除（macOS/Ubuntu 優先と整合） | **解消** |

### 12.4 残課題（追記推奨・ブロッカーではない）

改訂担当AIは、計画 `implementation_plan_008_0724.md` に以下を追記すること。

#### R1. PSI 入力契約の明示（優先度: 高）

現状の config 例（計画 §4 Component 3）:

```yaml
psi:
  enabled: true
  n_bins: 10
```

不足キー（R 正本 `calculate_psi` 相当）:

- `group_col`
- `baseline_group`
- `current_group`

追記すべき固定事項:

- PSI / KS は **行スコア融合に入れない**（`score_fusion` に `psi_weight` を置かない）。
- 出力は `summary.psi_metrics`（および必要なら KS 用サマリ）に限定する。
- 参照実装: `/Users/myamaguchi/.agents/skills/r-anomary-detection/scripts/utils.R` の `calculate_psi` / `compare_distribution_shift`

#### R2. STL 起動条件と合成データ（優先度: 高）

現状: `stl.enabled: false`、「時系列指定時に ON」、不規則系列はスキップ、とだけある。

追記すべき内容:

- config キー: `time_col`, `value_col`, `period`（計画例の `period: 7`）, 短系列時の最小長 / スキップ条件
- Phase 3 で `.agent/skills/anomaly-detection/scripts/generate_synth.py` を改修し、等間隔時系列・PSI用 baseline/current グループを持つ合成データを用意する
- 現行 synth の事実: `visit_date` は乱数日オフセット（等間隔TSではない）。baseline/current 列も無い  
  パス: `/Users/myamaguchi/Programing/rwd-mysql-skill-toolkit/.agent/skills/anomaly-detection/scripts/generate_synth.py`

#### R3. 相互運用成功条件を Verification に落とす（優先度: 中）

計画 §2 で Spearman を定義しているが、§5 検証計画に項目が無い。

追記例:

- 共通合成データで Python fused 順位と R fused 順位の Spearman 相関が閾値以上（閾値は計画で数値化、例: ≥ 0.7）
- または「アルゴリズム手順の共有テストベクターで正規化後スコアが許容誤差内」

#### R4. その他の薄い点（優先度: 低〜中）

| 項目 | 推奨追記 |
| --- | --- |
| `uv.lock` | Phase 1 で生成しリポジトリにコミットする方針 |
| 他 config | `configs/small-scale.yaml`, `configs/large-scale.yaml` も `default.yaml` に追随 |
| 解釈ガイド | `docs/Reference/anomaly-detection/anomaly_results_interpretation.md` を schema v0.2.0 に合わせて更新 |
| plan_002 | `docs/Artifacts/implementation_plan_002_0702_anomaly_vaccine_smoke.md` との前後関係（008後に再スモーク要否） |
| R Skill 非改変 | 008 は Python Skill のみ変更。`~/.agents/skills/r-anomary-detection/` は参照のみ |
| 実行ゲート | 「ユーザーが承認するまで実装しない」を計画本文に明記 |
| schema version の事実 | 現行 `output.schema.json` に version プロパティは **無い**。「現状=無版、改訂で初めて `schema_version` / 文書上 v0.2.0 を付与」と書く。計画が言う「現状 v0.1.0」はファイル上の事実ではない |

確認済み事実（再レビュー時）:

- `/Users/myamaguchi/Programing/rwd-mysql-skill-toolkit/.agent/skills/anomaly-detection/docs/schemas/output.schema.json` … `$schema` / `title` はあるが skill 側 version フィールド無し
- import: `pipeline.py` は `from .detectors import EnsembleDetector`（パッケージ化時は `__init__.py` エクスポートで互換維持する計画で妥当）

### 12.5 改訂第2版で維持すべき良い点

1. Phase 1–4 の依存順序が明確（uv → detectors/MCD → STL/PSI/KS → fusion/schema）
2. 相互運用定義が現実的（数値完全一致を要求しない）
3. PSI を行スコアではなく `summary` 側へ寄せる方向が正しい
4. `check_health.py` の L1/L2、CI の `setup-uv`、出力パス `skill_out/.../run_<id>/` がリポジトリ規則と整合
5. `score_fusion` 新重み例の合計が 1.0（0.30+0.10+0.20+0.15+0.15+0.10）
6. STL デフォルト無効は安全側

### 12.6 再レビュー用・計画追記チェックリスト

別AIが `implementation_plan_008_0724.md` を直すときの最小 ToDo:

- [ ] PSI: `group_col` / `baseline_group` / `current_group` を config 仕様に追加
- [ ] PSI/KS: 行 fusion 非投入・`summary.*` 出力を本文で固定
- [ ] STL: `time_col` / `value_col` / スキップ条件を追加
- [ ] Phase 3: `generate_synth.py` 改修を Component / Verification に追加
- [ ] §5 に Spearman（または共有ベクター）検証項目を追加
- [ ] （推奨）`uv.lock`、他 yaml、解釈ガイド、plan_002、R非改変、実行ゲート、schema 無版→v0.2.0 の事実修正

### 12.7 承認判断ガイド（再レビュー後・最新）

| 状態 | 判断 |
| --- | --- |
| 改訂第2版のまま（§12.4 未追記） | **条件付き承認可**（残課題を実装中に確定する前提）。慎重なら追記待ち |
| §12.6 の高優先（R1–R3）を追記済み | **承認推奨** |
| ユーザーが「承認します」「実行して」と明示 | 実装開始可。推奨は Phase 1 から順に |
| ユーザーが Phase 単位で承認する場合 | Phase 1（uv）のみ先に承認 → 完了報告 → Phase 2… も可 |

実装時の注意（承認後・初回 §9 と同趣旨）:

- 無関係な既存差分をコミットに混ぜない
- DB 更新系は別件
- PHI/PII・秘密情報を成果物に出さない
- R Skill 正本を改変しない

### 12.8 パス早見（再レビュー時点）

| 役割 | パス |
| --- | --- |
| 本レビュー（本追記を含む） | `docs/Artifacts/review_implementation_plan_008_0724.md` |
| 同上・絶対パス | `/Users/myamaguchi/Programing/rwd-mysql-skill-toolkit/docs/Artifacts/review_implementation_plan_008_0724.md` |
| 対象計画（改訂第2版） | `docs/Artifacts/implementation_plan_008_0724.md` |
| 同上・絶対パス | `/Users/myamaguchi/Programing/rwd-mysql-skill-toolkit/docs/Artifacts/implementation_plan_008_0724.md` |
| Python Skill | `.agent/skills/anomaly-detection/` |
| 現行 detectors（単一） | `.agent/skills/anomaly-detection/src/anomaly_detection/detectors.py` |
| 現行 fusion 位置 | `.agent/skills/anomaly-detection/src/anomaly_detection/pipeline.py`（L35–41 付近） |
| 現行 output schema | `.agent/skills/anomaly-detection/docs/schemas/output.schema.json` |
| 現行 synth | `.agent/skills/anomaly-detection/scripts/generate_synth.py` |
| R 正本 utils | `/Users/myamaguchi/.agents/skills/r-anomary-detection/scripts/utils.R` |

---

## 13. 実装評価とフォロー対応の点検（追記・最新）

> **別AIへの案内**: 本節が **2026-07-25 01:22 (JST) 時点の最新判定**。  
> 流れは **(A) 初回実装評価 → (B) 対応コメントの主張 → (C) 実コード照合 → (D) 残課題**。  
> 計画レビュー（§12）の承認判断とは別レイヤ（実装品質）である。

### 13.1 最新判定（1分で読む）

| 観点 | 判定 | 一言 |
| --- | --- | --- |
| コア実装（検出器 / fusion / uv 経路） | **達成** | Phase 1–4 の主機能は入っている |
| 初回実装評価時の完了条件 | **当時は未達** | Spearman名・lock・docs・`latest/` など |
| フォロー対応後 | **ほぼクローズ** | 後段コメントどおりの修正が実在 |
| 前段「R正本 Spearman」主張 | **未実施** | 後段の「Python 一貫性テストへ改名」が実態 |
| 全体 | **合格寄り・軽微残あり** | 下記 §13.5 の3点を直せば完了扱いに近い |

**再検証コマンド結果（点検時）**: `.agent/skills/anomaly-detection` で `uv run pytest tests/` → **12 passed**。

---

### 13.2 メタ情報

| 項目 | 値 |
| --- | --- |
| 点検日時 | 2026-07-25 01:22 (JST) |
| 点検者 | AI Agent (Composer) |
| 対象計画 | `docs/Artifacts/implementation_plan_008_0724.md`（改訂第3版・最終案） |
| 完了報告 | `docs/Artifacts/walkthrough_001_0725.md` |
| Skill ルート | `/Users/myamaguchi/Programing/rwd-mysql-skill-toolkit/.agent/skills/anomaly-detection/` |
| 本追記の入力 | (1) 初回実装評価ギャップ (2) 対応コメント2通の照合依頼 |

---

### 13.3 初回実装評価で指摘したギャップ（当時）

実装直後の評価では「機能は入ったが計画の完了条件は未達」とした。ギャップ一覧:

| ID | ギャップ | 当時の要点 |
| --- | --- | --- |
| G1 | Spearman 相互運用 | テスト名だけ。R比較なし。`spearmanr` 未使用 |
| G2 | `uv.lock` 追跡不可 | ルート `.gitignore` の `uv.lock` で無視 |
| G3 | ドキュメント未追随 | README / 解釈ガイドが v0.2.0 未反映 |
| G4 | `make infer` が `latest/` | `run_<id>/` 隔離ルールと矛盾 |
| G5 | schema 自動検証弱い | `test_schemas` が Request のみ。出力に version なし |
| G6 | L2 自動修復なし | `check_health` は案内のみ |
| G7 | ノイズ | デッド `detectors.py`、MCD 警告、CI が `uv pip` |

関連: walkthrough は一部「完了」と過大（例: lock コミット、Spearman、schema テスト）。

---

### 13.4 対応コメントの照合結果

実装側から **2通の対応コメント** が来た。内容が一部矛盾するため、**後段を正**、前段の R 主張は取り下げとして扱う。

#### 13.4.1 コメントの読み分け

| 通 | 主張の要旨 | 実コードとの関係 |
| --- | --- | --- |
| **前段** | R正本 `calculate_fused_anomaly_score` 同等参照で Spearman ≥0.70 | **未実装** |
| **後段** | テストを `test_score_fusion_rank_correlation.py` に改名し Python 一貫性検証へ | **実装済み（こちらが正）** |

#### 13.4.2 項目別チェック表

凡例: **達** = 主張どおり / **部分** = 意図はあるが表記・実装がずれ / **未達** = 主張と不一致

| ID | 主張（要約） | 結果 | 確認ポイント |
| --- | --- | --- | --- |
| G1 前段 | R正本と Spearman ≥0.70 | **未達** | R 呼び出しなし |
| G1 後段 | 名称・目的を Python ランク相関に整合 | **達** | `tests/test_score_fusion_rank_correlation.py` のみ存在。旧 `test_spearman_interop.py` 削除 |
| G2 / 後段1 | `!.agent/skills/anomaly-detection/uv.lock` のみ追加 | **達** | `.gitignore` 差分は当該1行。`uv.lock` は `??` で `git add` 可能。無関係な大量差分は撤回済み |
| G3 | README / 解釈ガイドを v0.2.0・uv・MCD・STL・PSI に更新 | **おおむね達** | 記載あり。出力仕様の誤りは §13.5-R1 |
| G4 | `make infer` → `run_$(RUN_ID)/` | **達** | `Makefile` の `RUN_ID` / 出力パス |
| G5 | `schema_version: "v0.2.0"` + `jsonschema.validate` | **達** | `pipeline.py` 戻り値、`tests/test_schemas.py` |
| G6 | L2 で `uv sync` 自動修復 | **部分** | 自動再試行はある。実コマンドは `uv pip install -e '.[dev]'`（表示だけ sync） |
| G7a | MCD 低分散列除外・警告抑制 | **達** | `detectors/mcd.py`、pytest 警告なし |
| G7b / 後段5 | CI を `uv sync --frozen --all-extras` | **達（記述）** | `ci.yml` 更新済み。スキル配下 `.github` は monorepo で通常未起動（従来課題） |
| 後段5 | デッド `detectors.py` 削除 | **達** | git status 上 `D .../detectors.py`。パッケージ `detectors/` に一本化 |

#### 13.4.3 G1 テストの実態（誤解防止）

ファイル: `.agent/skills/anomaly-detection/tests/test_score_fusion_rank_correlation.py`

- やっていること: `run_detection` の `score` と、同一 `model_contributions` の加重和との **Spearman ≥ 0.70**
- やっていないこと: R 正本との相互運用、共通ベクターでの言語横断比較
- 評価: 命名・目的は後段どおりで妥当。ただし相関は通りやすく、**弱い回帰テスト**にとどまる

---

### 13.5 残課題（フォロー後も残るもの）

優先度順。ブロッカー級ではない。

#### R1. 解釈ガイドの出力仕様が実ファイルと不一致（高）

対象: `docs/Reference/anomaly-detection/anomaly_results_interpretation.md`（L13–15 付近）

| ガイドの記述 | 実装の事実 |
| --- | --- |
| JSONL 各行に `schema_version` | 行は `record_id` / `score` / … のみ。`schema_version` は pipeline 戻り値トップレベル |
| JSONL 末尾に `psi_metrics` / `ks_metrics` | `cli.py` は `results` のみ `write_jsonl`。summary は **stdout print** |

対応案（どちらか）:

1. ガイドを実挙動に合わせて修正する  
2. summary / `schema_version` を別ファイルまたは JSONL 末尾行として永続化する

#### R2. L2 の文言と実装の不一致（中）

- コメント・ログ: `uv sync`
- 実装: `subprocess` で `uv pip install -e '.[dev]'`（`scripts/check_health.py`）

lock 決定論と揃えるなら `uv sync --extra dev`（または同等）へ寄せる。

#### R3. 運用・CI の磨き（低）

| 項目 | 内容 |
| --- | --- |
| `jsonschema` | `dev` extra のみ。`check_health` は必須扱い → 最小 sync だと health 失敗→L2 誘発 |
| CI `--all-extras` | `deep`（torch）まで入り重い。`--extra dev` の方が安全 |
| monorepo CI | ワークフローが `.agent/skills/anomaly-detection/.github/` 配下のため、ルート Actions では動かない可能性 |

---

### 13.6 フォロー後のクローズ判定

#### 実質クローズしてよいもの

- G2 `uv.lock` 追跡許可（gitignore 整理込み）
- G3 ドキュメント更新（R1 の仕様文言を除く）
- G4 `run_<id>/` 隔離
- G5 schema version + jsonschema 検証
- G7a MCD 警告対策
- デッド `detectors.py` 削除
- テスト命名の実態整合（後段 G1）
- pytest 緑（12 passed）

#### まだ「コメントどおり」ではないもの

- 前段 G1（R 相互運用 Spearman）→ **未実施 / 後段で方針変更**
- G6（L2 = 本当の `uv sync`）→ **部分**
- 解釈ガイド JSONL 記述（R1）→ **要修正**

#### 推奨ネクストアクション

1. R1: 解釈ガイド修正、または summary 永続化  
2. R2: L2 を `uv sync` 系に統一  
3. （任意）R3: CI extra 絞り込み  
4. （任意）真の Python↔R Spearman が必要なら別タスクとして計画化（現状テストでは代替しない）

---

### 13.7 パス早見（実装後・点検時点）

| 役割 | パス |
| --- | --- |
| 本レビュー（§13 含む） | `docs/Artifacts/review_implementation_plan_008_0724.md` |
| 計画 | `docs/Artifacts/implementation_plan_008_0724.md` |
| Walkthrough | `docs/Artifacts/walkthrough_001_0725.md` |
| 解釈ガイド | `docs/Reference/anomaly-detection/anomaly_results_interpretation.md` |
| Skill README | `.agent/skills/anomaly-detection/README.md` |
| Fusion | `.agent/skills/anomaly-detection/src/anomaly_detection/fusion.py` |
| Detectors パッケージ | `.agent/skills/anomaly-detection/src/anomaly_detection/detectors/` |
| ランク相関テスト | `.agent/skills/anomaly-detection/tests/test_score_fusion_rank_correlation.py` |
| Schema テスト | `.agent/skills/anomaly-detection/tests/test_schemas.py` |
| Health | `.agent/skills/anomaly-detection/scripts/check_health.py` |
| Makefile | `.agent/skills/anomaly-detection/Makefile` |
| CI | `.agent/skills/anomaly-detection/.github/workflows/ci.yml` |
| Lock | `.agent/skills/anomaly-detection/uv.lock` |
| 出力 schema | `.agent/skills/anomaly-detection/docs/schemas/output.schema.json` |

絶対パス接頭辞: `/Users/myamaguchi/Programing/rwd-mysql-skill-toolkit/`
