# Git push 失敗時の手順（ローカルとリモートが分岐した場合）

created: 2026-03-01 10:30 (JST)
author: AI Agent (LLM Model)

## 原因

- リモート（GitHub 等）で main に別のコミットが入ったあと、ローカルでコミットして `git push` すると「non-fast-forward」で拒否される。
- ローカルとリモートが「1 and 1 different commits each」のように分岐している状態。

## 手順（推奨: pull --rebase してから push）

1. **状態確認**
   ```bash
   git status
   git log -2 --oneline
   ```

2. **リモートの変更を取り込みつつ、自分のコミットをその上に載せる**
   ```bash
   git pull --rebase origin main
   ```

3. **コンフリクトが出た場合**
   - 該当ファイルの `<<<<<<<` / `=======` / `>>>>>>>` を解消する。
   - 解消後:
     ```bash
     git add <解消したファイル>
     GIT_EDITOR=true git rebase --continue
     ```
   - 続けてコンフリクトが出たら同様に解消して `git add` → `GIT_EDITOR=true git rebase --continue` を繰り返す。

4. **rebase 完了後に push**
   ```bash
   git push origin main
   ```

## 補足

- **`GIT_EDITOR=true`** は「既定のコミットメッセージのまま保存して終了」させるため。指定しないと `git rebase --continue` で vim 等が開き、操作が止まることがある。
- どうしても rebase をやめたいときは `git rebase --abort`。作業ツリーの変更は残るが、rebase 前の状態に戻る。
- 今後、**push の前に必ず `git pull --rebase origin main` を実行する**習慣にすると、同じ失敗を防ぎやすい。
