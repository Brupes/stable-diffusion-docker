#!/bin/bash

if [ -f "/app/venv" ]; then
    uv venv /app/venv --python 3.13 --seed
fi
source /app/venv/bin/activate

./webui.sh