#!/bin/bash
# vcd-categorical-analysis/tests/verify_skill.sh
# 
# Usage: bash verify_skill.sh

set -e

SCRIPT_DIR=$(cd $(dirname $0); pwd)
SKILL_DIR=$(dirname "$SCRIPT_DIR")
PROJECT_ROOT=$(cd "$SKILL_DIR/../../.."; pwd)
ANALYSIS_R="$SKILL_DIR/templates/analysis.R"
TEST_OUT="$PROJECT_ROOT/skill_out/vcd_categorical_test"

echo "[TEST] Starting verification for vcd-categorical-analysis..."
echo "[TEST] Skill directory: $SKILL_DIR"
echo "[TEST] Output directory: $TEST_OUT"

# 1. Check R installation
if ! command -v Rscript &> /dev/null; then
    echo "Error: Rscript not found in PATH"
    exit 1
fi

# 2. Cleanup previous test output
rm -rf "$TEST_OUT"
mkdir -p "$TEST_OUT"

# 3. Test Pass 1: Profiling (Default data)
echo "[TEST] Running Pass 1 (Profiling - Default)..."
Rscript "$ANALYSIS_R" --profile --out "$TEST_OUT"

if [ ! -f "$TEST_OUT/data_profile.json" ]; then
    echo "Error: data_profile.json not found"
    exit 1
fi
echo "[PASS] Pass 1 completed."

# 4. Test Pass 2: Rendering (Default data)
echo "[TEST] Running Pass 2 (Rendering - Default)..."
Rscript "$ANALYSIS_R" --render --out "$TEST_OUT"

# Verify files
FILES=(
    "summary_haireye.json"
    "residuals_haireye.csv"
    "mosaic_haireye.png"
    "matrix_marginal_haireye.html"
    "dt_residuals_haireye.html"
)

for f in "${FILES[@]}"; do
    if [ ! -f "$TEST_OUT/$f" ]; then
        echo "Error: Required file $f not found in $TEST_OUT"
        exit 1
    fi
done
echo "[PASS] Pass 2 (Default) completed."

# 5. Test with External CSV (if Q09_long.csv exists in root)
Q09_PATH="$PROJECT_ROOT/Q09_long.csv"
if [ -f "$Q09_PATH" ]; then
    echo "[TEST] Running Pass 2 with external CSV (Q09_long.csv)..."
    Rscript "$ANALYSIS_R" --render --data "$Q09_PATH" --vars "symptom,drug,timing" --freq "Freq" --label "q09_test" --out "$TEST_OUT"
    
    if [ ! -f "$TEST_OUT/summary_q09_test.json" ]; then
        echo "Error: External CSV summary not found"
        exit 1
    fi
    echo "[PASS] External CSV test completed."
else
    echo "[SKIP] Q09_long.csv not found, skipping external test."
fi

echo "[SUCCESS] vcd-categorical-analysis verification passed!"
exit 0
