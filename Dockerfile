FROM nvidia/cuda:12.1.1-cudnn8-runtime-ubuntu22.04

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3.10 \
    python3.10-venv \
    python3-pip \
    wget \
    unzip \
    git \
    libgl1 \
    libglib2.0-0 \
    libgoogle-perftools4 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /app

ARG STABLE_DIFFUSION_VERSION

RUN wget https://github.com/AUTOMATIC1111/stable-diffusion-webui/archive/refs/tags/v${STABLE_DIFFUSION_VERSION}.zip
RUN unzip v${STABLE_DIFFUSION_VERSION}.zip
RUN mv stable-diffusion-webui-${STABLE_DIFFUSION_VERSION} stable-diffusion-webui

WORKDIR /app/stable-diffusion-webui

RUN python3.10 -m venv venv
ENV PATH="/app/stable-diffusion-webui/venv/bin:$PATH"

RUN pip install --upgrade pip wheel setuptools
RUN pip install torch==2.1.2 torchvision==0.16.2 --index-url https://download.pytorch.org/whl/cu121
RUN pip install xformers==0.0.23.post1
RUN pip install -r requirements_versions.txt

RUN mkdir -p repositories

# assets
RUN git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui-assets.git repositories/stable-diffusion-webui-assets
RUN cd repositories/stable-diffusion-webui-assets && \
    git checkout 6f7db241d2f8ba7457bac5ca9753331f0c266917 && \
    cd ../..
# Stable Diffusion XL
RUN git clone https://github.com/Stability-AI/generative-models.git repositories/generative-models
RUN cd repositories/generative-models && \
    git checkout 45c443b316737a4ab6e40413d7794a7f5657c19f && \
    cd ../..
# K-diffusion
RUN git clone https://github.com/crowsonkb/k-diffusion.git repositories/k-diffusion
RUN cd repositories/k-diffusion && \
    git checkout ab527a9a6d347f364e3d185ba6d714e22d80cb3c && \
    cd ../..
# BLIP
RUN git clone https://github.com/salesforce/BLIP.git repositories/BLIP
RUN cd repositories/BLIP && \
    git checkout 48211a1594f1321b00f14c9f7a5b4813144b2fb9 && \
    cd ../..
# Stable Diffusion
RUN git clone https://github.com/joypaul162/Stability-AI-stablediffusion.git repositories/stable-diffusion-stability-ai
RUN cd repositories/stable-diffusion-stability-ai && \
    git checkout cf1d67a6fd5ea1aa600c4df58e5b47da45f6bdbf && \
    cd ../..

RUN pip install "setuptools<81"
RUN pip install git+https://github.com/openai/CLIP.git@d50d76daa670286dd6cacf3bcd80b5e4823fc8e1 --no-build-isolation --prefer-binary

# ENV NO_TCMALLOC=true

WORKDIR /app
RUN cp stable-diffusion-webui/webui.sh ./

EXPOSE 7860

CMD ["./webui.sh", "-f", "--listen", "--port", "7860", "--skip-torch-cuda-test", "--enable-insecure-extension-access"]