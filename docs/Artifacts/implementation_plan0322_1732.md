# QNAP-MariaDB UCBAdmissions データインサート実行計画

created: 2026-03-22 17:32 (JST)
author: AI Agent (Gemini 2.0 Pro)

R言語の組み込みデータセットである `UCBAdmissions`（カリフォルニア大学バークレー校の大学院入試に関する性別・学科・合否データ）を、QNAP NAS 上の MariaDB の `Training` データベースに投入し、内容を表示します。

## 実行ステップ

### 1. テーブルの作成 (DDL)
`Training` データベースに `UCBAdmissions` テーブルを新規作成します。すでに存在する場合は削除して作り直します（洗い替え）。

```sql
USE Training;
DROP TABLE IF EXISTS UCBAdmissions;
CREATE TABLE UCBAdmissions (
  id INT AUTO_INCREMENT PRIMARY KEY,
  Admit VARCHAR(20),
  Gender VARCHAR(20),
  Dept VARCHAR(10),
  Freq INT
);
```

### 2. データのインサート (DML)
Rのデータセットから展開された24行のレコードを一括インサートします。

```sql
INSERT INTO UCBAdmissions (Admit, Gender, Dept, Freq) VALUES
  ("Admitted", "Male", "A", 512),
  ("Rejected", "Male", "A", 313),
  ("Admitted", "Female", "A", 89),
  ("Rejected", "Female", "A", 19),
  ("Admitted", "Male", "B", 353),
  ("Rejected", "Male", "B", 207),
  ("Admitted", "Female", "B", 17),
  ("Rejected", "Female", "B", 8),
  ("Admitted", "Male", "C", 120),
  ("Rejected", "Male", "C", 205),
  ("Admitted", "Female", "C", 202),
  ("Rejected", "Female", "C", 391),
  ("Admitted", "Male", "D", 138),
  ("Rejected", "Male", "D", 279),
  ("Admitted", "Female", "D", 131),
  ("Rejected", "Female", "D", 244),
  ("Admitted", "Male", "E", 53),
  ("Rejected", "Male", "E", 138),
  ("Admitted", "Female", "E", 94),
  ("Rejected", "Female", "E", 299),
  ("Admitted", "Male", "F", 22),
  ("Rejected", "Male", "F", 351),
  ("Admitted", "Female", "F", 24),
  ("Rejected", "Female", "F", 317);
```

### 3. テーブル内容の確認 (SELECT)
データが正常に挿入されたことを確認するため、内容を抽出して表示します。

```sql
SELECT * FROM Training.UCBAdmissions;
```

---
> [!IMPORTANT]
> **ユーザーへの確認事項**
> 本ドキュメントの内容に問題がなければ、「実行して」または「承認します」とご指示をお願いいたします。承認後、ただちにMCPツールを用いてリモートDB（QNAP）への書き込みを実施します。
