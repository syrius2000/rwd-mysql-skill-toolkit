#!/bin/bash
#
# setup_csv_import_tools.sh
# CSVインポートツールを新しいディレクトリに設置するスクリプト
#
# 使い方:
#   ./setup_csv_import_tools.sh [オプション] [設置先ディレクトリ]
#
# 例:
#   ./setup_csv_import_tools.sh --target-dir /path/to/new_csv_data
#   ./setup_csv_import_tools.sh --target-dir ./new_data --copy --include-docs
#   ./setup_csv_import_tools.sh --target-dir ./new_data --link --include-prompt

set -euo pipefail  # エラー時に停止、未定義変数エラー、パイプエラー検出

# カラー出力設定
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# スクリプトのディレクトリを取得（ソースディレクトリとして使用）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$SCRIPT_DIR"

# デフォルト設定
TARGET_DIR=""
USE_LINK=false
INCLUDE_DOCS=false
INCLUDE_PROMPT=false
ROLLBACK_ON_ERROR=false

# 必須ファイル
REQUIRED_FILES=(
    "MakeSampleSQLfiles.py"
    "readme.md"
)

# 推奨ファイル（オプション）
OPTIONAL_FILES=(
    "MakeSampleSQLfiles_SPEC.md"
    "MakeSampleSQLfiles_Design_Addendum.md"
)

# プロンプトファイル
PROMPT_FILE=".github/prompts/SQLimport.prompt.md"

# 使用方法を表示
show_usage() {
    cat << EOF
${CYAN}CSVインポートツール設置スクリプト${NC}

${BLUE}使い方:${NC}
  $0 [オプション] [設置先ディレクトリ]

${BLUE}オプション:${NC}
  --target-dir DIR     設置先ディレクトリを指定（必須）
  --source-dir DIR     ソースディレクトリを指定（デフォルト: スクリプトの場所）
  --copy               ファイルをコピー（デフォルト）
  --link               シンボリックリンクを作成
  --include-docs       推奨ドキュメントも含める
  --include-prompt     AIプロンプトファイルも含める
  --rollback           エラー時にロールバック
  --help               このヘルプを表示

${BLUE}例:${NC}
  # 基本的な設置（ファイルコピー）
  $0 --target-dir /path/to/new_csv_data

  # シンボリックリンクで設置
  $0 --target-dir ./new_data --link

  # ドキュメントとプロンプトファイルも含める
  $0 --target-dir ./new_data --copy --include-docs --include-prompt

  # エラー時にロールバック
  $0 --target-dir ./new_data --rollback
EOF
}

# エラーメッセージを表示して終了
error_exit() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
    exit 1
}

# 情報メッセージ
info_msg() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# 成功メッセージ
success_msg() {
    echo -e "${GREEN}[OK]${NC} $1"
}

# 警告メッセージ
warn_msg() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Python環境のチェック
check_python() {
    info_msg "Python環境を確認中..."
    
    if ! command -v python3 &> /dev/null; then
        error_exit "Python 3がインストールされていません。インストールしてください。"
    fi
    
    local python_version=$(python3 --version 2>&1 | awk '{print $2}')
    local major_version=$(echo "$python_version" | cut -d. -f1)
    local minor_version=$(echo "$python_version" | cut -d. -f2)
    
    if [ "$major_version" -lt 3 ] || ([ "$major_version" -eq 3 ] && [ "$minor_version" -lt 7 ]); then
        error_exit "Python 3.7以上が必要です。現在のバージョン: $python_version"
    fi
    
    success_msg "Python $python_version を確認"
}

# ソースファイルの存在確認
check_source_files() {
    info_msg "ソースファイルを確認中..."
    
    local missing_files=()
    
    for file in "${REQUIRED_FILES[@]}"; do
        if [ ! -f "$SOURCE_DIR/$file" ]; then
            missing_files+=("$SOURCE_DIR/$file")
        fi
    done
    
    if [ ${#missing_files[@]} -gt 0 ]; then
        error_exit "必須ファイルが見つかりません: ${missing_files[*]}"
    fi
    
    success_msg "必須ファイルを確認"
}

# ディレクトリ構造の作成
create_directory_structure() {
    info_msg "ディレクトリ構造を作成中..."
    
    local dirs=("$TARGET_DIR" "$TARGET_DIR/data" "$TARGET_DIR/tools" "$TARGET_DIR/output")
    
    if [ "$INCLUDE_PROMPT" = true ]; then
        dirs+=("$TARGET_DIR/.github/prompts")
    fi
    
    for dir in "${dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            success_msg "ディレクトリを作成: $dir"
        else
            warn_msg "ディレクトリは既に存在します: $dir"
        fi
    done
}

# ファイルをコピーまたはリンク作成
setup_file() {
    local source_file="$1"
    local target_file="$2"
    local file_name=$(basename "$source_file")
    
    if [ ! -f "$source_file" ]; then
        warn_msg "ファイルが見つかりません（スキップ）: $source_file"
        return 1
    fi
    
    if [ -f "$target_file" ] || [ -L "$target_file" ]; then
        warn_msg "ファイルは既に存在します（スキップ）: $target_file"
        return 0
    fi
    
    if [ "$USE_LINK" = true ]; then
        # 相対パスでシンボリックリンクを作成
        local rel_path=$(realpath --relative-to="$(dirname "$target_file")" "$source_file" 2>/dev/null || echo "$source_file")
        ln -s "$rel_path" "$target_file"
        success_msg "シンボリックリンクを作成: $file_name"
    else
        cp "$source_file" "$target_file"
        success_msg "ファイルをコピー: $file_name"
    fi
    
    # Pythonスクリプトの場合は実行権限を付与
    if [[ "$file_name" == *.py ]]; then
        chmod +x "$target_file"
    fi
    
    return 0
}

# 必須ファイルの設置
setup_required_files() {
    info_msg "必須ファイルを設置中..."
    
    for file in "${REQUIRED_FILES[@]}"; do
        setup_file "$SOURCE_DIR/$file" "$TARGET_DIR/tools/$file"
    done
}

# 推奨ファイルの設置
setup_optional_files() {
    if [ "$INCLUDE_DOCS" != true ]; then
        return 0
    fi
    
    info_msg "推奨ドキュメントを設置中..."
    
    for file in "${OPTIONAL_FILES[@]}"; do
        setup_file "$SOURCE_DIR/$file" "$TARGET_DIR/tools/$file"
    done
}

# プロンプトファイルの設置
setup_prompt_file() {
    if [ "$INCLUDE_PROMPT" != true ]; then
        return 0
    fi
    
    info_msg "AIプロンプトファイルを設置中..."
    
    local prompt_source="$SCRIPT_DIR/../$PROMPT_FILE"
    local prompt_target="$TARGET_DIR/$PROMPT_FILE"
    
    if [ ! -f "$prompt_source" ]; then
        warn_msg "プロンプトファイルが見つかりません（スキップ）: $prompt_source"
        return 1
    fi
    
    setup_file "$prompt_source" "$prompt_target"
}

# スクリプトの動作確認
verify_setup() {
    info_msg "設置を確認中..."
    
    local errors=0
    
    # 必須ファイルの確認
    for file in "${REQUIRED_FILES[@]}"; do
        if [ ! -f "$TARGET_DIR/tools/$file" ] && [ ! -L "$TARGET_DIR/tools/$file" ]; then
            error_exit "必須ファイルが設置されていません: $file"
            ((errors++))
        fi
    done
    
    # Pythonスクリプトの動作確認
    if [ -f "$TARGET_DIR/tools/MakeSampleSQLfiles.py" ]; then
        if ! python3 "$TARGET_DIR/tools/MakeSampleSQLfiles.py" --help > /dev/null 2>&1; then
            warn_msg "Pythonスクリプトの動作確認に失敗しました（続行します）"
        else
            success_msg "Pythonスクリプトの動作を確認"
        fi
    fi
    
    if [ $errors -eq 0 ]; then
        success_msg "設置が正常に完了しました"
        return 0
    else
        error_exit "設置の確認中に $errors 個のエラーが見つかりました"
    fi
}

# ロールバック処理
rollback() {
    if [ "$ROLLBACK_ON_ERROR" != true ]; then
        return 0
    fi
    
    warn_msg "ロールバックを実行中..."
    
    if [ -d "$TARGET_DIR/tools" ]; then
        rm -rf "$TARGET_DIR/tools"
    fi
    
    if [ -d "$TARGET_DIR/.github" ]; then
        rm -rf "$TARGET_DIR/.github"
    fi
    
    if [ -d "$TARGET_DIR/output" ]; then
        rm -rf "$TARGET_DIR/output"
    fi
    
    # dataディレクトリは削除しない（ユーザーのデータが含まれる可能性があるため）
    
    info_msg "ロールバックが完了しました"
}

# 引数解析
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --target-dir)
                TARGET_DIR="$2"
                shift 2
                ;;
            --source-dir)
                SOURCE_DIR="$2"
                shift 2
                ;;
            --copy)
                USE_LINK=false
                shift
                ;;
            --link)
                USE_LINK=true
                shift
                ;;
            --include-docs)
                INCLUDE_DOCS=true
                shift
                ;;
            --include-prompt)
                INCLUDE_PROMPT=true
                shift
                ;;
            --rollback)
                ROLLBACK_ON_ERROR=true
                shift
                ;;
            --help)
                show_usage
                exit 0
                ;;
            -*)
                error_exit "不明なオプション: $1"
                ;;
            *)
                if [ -z "$TARGET_DIR" ]; then
                    TARGET_DIR="$1"
                else
                    error_exit "複数の設置先ディレクトリが指定されました: $TARGET_DIR と $1"
                fi
                shift
                ;;
        esac
    done
    
    # 設置先ディレクトリの確認
    if [ -z "$TARGET_DIR" ]; then
        error_exit "設置先ディレクトリが指定されていません。--target-dir オプションを使用してください。"
    fi
    
    # 絶対パスに変換
    TARGET_DIR="$(cd "$(dirname "$TARGET_DIR")" && pwd)/$(basename "$TARGET_DIR")"
    SOURCE_DIR="$(cd "$SOURCE_DIR" && pwd)"
}

# メイン処理
main() {
    echo "======================================"
    echo "  CSVインポートツール設置スクリプト"
    echo "======================================"
    echo "ソースディレクトリ: $SOURCE_DIR"
    echo "設置先ディレクトリ: $TARGET_DIR"
    echo "モード: $([ "$USE_LINK" = true ] && echo "シンボリックリンク" || echo "コピー")"
    echo "======================================"
    echo ""
    
    # 環境チェック
    check_python
    check_source_files
    
    # ディレクトリ構造の作成
    create_directory_structure
    
    # ファイルの設置
    setup_required_files
    setup_optional_files
    setup_prompt_file
    
    # 動作確認
    verify_setup
    
    # 完了メッセージ
    echo ""
    echo "======================================"
    success_msg "設置が完了しました！"
    echo "======================================"
    echo ""
    echo "次のステップ:"
    echo "  1. CSV/TXTファイルを $TARGET_DIR/data/ に配置"
    echo "  2. SQL雛形を生成:"
    echo "     cd $TARGET_DIR"
    echo "     python3 tools/MakeSampleSQLfiles.py data/"
    echo ""
    
    if [ "$INCLUDE_PROMPT" = true ]; then
        echo "  AIプロンプトファイル: $TARGET_DIR/$PROMPT_FILE"
        echo "  Cursor IDEで使用する場合は、このファイルを参照してください"
        echo ""
    fi
    
    echo "詳細は $TARGET_DIR/tools/readme.md を参照してください"
    echo ""
}

# エラートラップ（ロールバック用）
trap 'if [ $? -ne 0 ] && [ "$ROLLBACK_ON_ERROR" = true ]; then rollback; fi' EXIT

# スクリプト実行
parse_arguments "$@"
main

