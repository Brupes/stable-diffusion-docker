FROM nvidia/cuda:13.2.0-cudnn-runtime-ubuntu24.04

# Install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    unzip \
    git \
    libgl1 \
    libglib2.0-0 \
    libgoogle-perftools4 \
    bc \
    build-essential \
    g++ \
    gcc \
    libcairo2-dev \
    pkg-config \
    libssl-dev \
    libffi-dev \
    ffmpeg \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install UV
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv
COPY --from=ghcr.io/astral-sh/uv:latest /uvx /usr/local/bin/uvx

# Install Python
RUN apt-get update && apt-get install -y --no-install-recommends \
    software-properties-common \
    && add-apt-repository ppa:deadsnakes/ppa -y
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3.13 \
    python3.13-venv \
    python3.13-dev \
    python3-pip \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Set Python 3.13 as the default python3
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 1
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.13 2
RUN update-alternatives --set python3 /usr/bin/python3.13
RUN ln -sf /usr/include/python3.13 /usr/include/python3 && \
    ln -sf /usr/bin/python3.13-config /usr/bin/python3-config

# Install Stable Diffusion WebUI Forge Classic
WORKDIR /app
ARG STABLE_DIFFUSION_VERSION=2.16

RUN wget https://github.com/Haoming02/sd-webui-forge-classic/archive/refs/tags/${STABLE_DIFFUSION_VERSION}.zip
RUN unzip ${STABLE_DIFFUSION_VERSION}.zip
RUN mv /app/sd-webui-forge-classic-${STABLE_DIFFUSION_VERSION}/* /app
RUN rm ${STABLE_DIFFUSION_VERSION}.zip

ADD scripts/start.sh ./
ADD scripts/webui.sh ./

RUN chmod +x /app/webui.sh /app/start.sh

EXPOSE 7860

CMD ["/app/start.sh"]