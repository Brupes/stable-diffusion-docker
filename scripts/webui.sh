#!/usr/bin/env bash

set -euo pipefail

# Source custom settings if it exists
[[ -f webui-user.sh ]] && source webui-user.sh

# Defaults
: "${PYTHON:=python3}"
: "${VENV_DIR:=$(pwd)/venv}"
: "${SD_WEBUI_RESTART:=tmp/restart}"
: "${ERROR_REPORTING:=FALSE}"
: "${SKIP_VENV:=0}"

if [[ -n "${GIT:-}" ]]; then
    export GIT_PYTHON_GIT_EXECUTABLE="$GIT"
fi

mkdir -p tmp 2>/dev/null

# Helper: run command and capture output for error display
run_and_capture() {
    local cmd=("$@")
    local out="tmp/stdout.txt"
    local err="tmp/stderr.txt"
    "${cmd[@]}" >"$out" 2>"$err"
    return $?
}

show_error() {
    local exitcode=$?
    echo
    echo "exit code: $exitcode"
    echo

    local stdout_size=$(stat -c %s tmp/stdout.txt 2>/dev/null || echo 0)
    if (( stdout_size > 0 )); then
        echo "stdout:"
        cat tmp/stdout.txt
        echo
    fi

    local stderr_size=$(stat -c %s tmp/stderr.txt 2>/dev/null || echo 0)
    if (( stderr_size > 0 )); then
        echo "stderr:"
        cat tmp/stderr.txt
        echo
    fi

    echo "Launch Unsuccessful! Exiting..."
    read -p "Press Enter to continue..."
    exit 1
}

# Check python / uv
if run_and_capture uv python; then
    echo "uv python check passed"
elif run_and_capture "$PYTHON" -c "import sys; sys.exit(0)"; then
    echo "Fallback python check passed"
else
    echo "Couldn't launch python"
    show_error
fi

# Check pip
if run_and_capture uv pip; then
    :
elif run_and_capture "$PYTHON" -m pip --help; then
    :
else
    echo "Couldn't launch pip"
    show_error
fi

# Handle venv skip cases
if [[ "$VENV_DIR" == "-" || "${SKIP_VENV:-0}" == "1" ]]; then
    # Skip venv → go straight to launch
    PYTHON_TO_USE="$PYTHON"
else
    # Check if venv already exists
    if [[ -x "$VENV_DIR/bin/python" ]]; then
        PYTHON_TO_USE="$VENV_DIR/bin/python"
    else
        # Create venv
        PYTHON_FULLNAME=$("$PYTHON" -c "import sys; print(sys.executable)" 2>/dev/null || echo "$PYTHON")
        echo "Creating venv in $VENV_DIR using $PYTHON_FULLNAME"

        if ! "$PYTHON_FULLNAME" -m venv "$VENV_DIR" >tmp/stdout.txt 2>tmp/stderr.txt; then
            echo "Unable to create venv in \"$VENV_DIR\""
            show_error
        fi

        # Upgrade pip (non-fatal)
        "$VENV_DIR/bin/python" -m pip install --upgrade pip || {
            echo "Warning: Failed to upgrade PIP"
        }

        PYTHON_TO_USE="$VENV_DIR/bin/python"
    fi

    # Activate (sets PATH, etc.)
    source "$VENV_DIR/bin/activate"
    echo "venv activated → python = $(which python)"
fi

# Launch the app
"$PYTHON_TO_USE" launch.py "$@"

# Auto-restart logic (if launch.py creates the restart file)
if [[ -f "$SD_WEBUI_RESTART" ]]; then
    rm -f "$SD_WEBUI_RESTART" 2>/dev/null || true
    echo "Restart requested — relaunching script"
    SKIP_VENV=1 exec "$0" "$@"
fi

exit 0