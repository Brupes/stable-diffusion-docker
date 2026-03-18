#!/bin/bash

source /app/venv/bin/activate

if [ -f "/app/venv/inited" ]; then
    echo "virtual environment already initialized, skipping installation"
else
    echo "Initializing virtual environment"
    pip install --upgrade pip wheel
    pip install -r requirements_versions.txt
    pip install git+https://github.com/openai/CLIP.git@d50d76daa670286dd6cacf3bcd80b5e4823fc8e1 --no-build-isolation --prefer-binary
    pip install setuptools xformers torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128
    pip install mediapipe==0.10.14
    touch /app/venv/inited
fi

exec ./webui.sh -f --precision full --listen --port 7860 --skip-torch-cuda-test --no-half --no-half-vae --enable-insecure-extension-access