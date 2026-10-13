#!/bin/bash

# Ensure the script always exits with code 0 so Claude Code never fails
trap 'exit 0' EXIT ERR INT TERM

# Navigate to project root if available
if [ -n "${CLAUDE_PROJECT_DIR:-}" ] && [ -d "$CLAUDE_PROJECT_DIR" ]; then
    cd "$CLAUDE_PROJECT_DIR" || exit 0
fi

# Read JSON payload from stdin
INPUT=$(cat 2>/dev/null || true)

# Extract file paths safely using jq
FILE_PATHS=$(echo "$INPUT" | jq -r '
  .tool_input as $input |
  [$input.file_path, ($input.file_paths[]?)] | map(select(. != null))[]
' 2>/dev/null || true)

# Flag to track if any Dart file was modified
HAS_DART_FILE=false

for FILE_PATH in $FILE_PATHS; do
    if [[ "$FILE_PATH" == *.dart ]]; then
        HAS_DART_FILE=true
        break
    fi
done

# If no Dart files were edited/created, exit cleanly without running any commands
if [ "$HAS_DART_FILE" = false ]; then
    exit 0
fi

echo "Dart file change detected. Running Dart tools once..."

# Navigate to the project root directory
cd "$CLAUDE_PROJECT_DIR" || exit 0

# 1. Apply quick fixes to the project/modified files
dart fix --apply > /dev/null 2>&1 || true

# 2. Format the project/files
dart format . > /dev/null 2>&1 || true

# 3. Analyze and log any errors/warnings to a separate log file
LOG_FILE="dart_analyze_errors.log"

# Run analyzer, capturing both stdout and stderr into the log file
dart analyze > "$LOG_FILE" 2>&1 || true

# Clean up empty log file if no errors or output were generated
if [ ! -s "$LOG_FILE" ]; then
    rm -f "$LOG_FILE"
else
    echo "Dart analyze output written to: $LOG_FILE"
fi

exit 0