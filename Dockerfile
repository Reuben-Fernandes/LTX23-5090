# ── Base ─────────────────────────────────────────────────────────
FROM vastai/base-image:cuda-12.8.1-cudnn-devel-ubuntu22.04-py312

ENV HF_HUB_ENABLE_HF_TRANSFER=1
ENV DEBIAN_FRONTEND=noninteractive
ENV PORTAL_CONFIG="localhost:1111:11111:/:Instance Portal|localhost:8188:18188:/:ComfyUI|localhost:8080:18080:/:Jupyter|localhost:8080:8080:/terminals/1:Jupyter Terminal"
ENV OPEN_BUTTON_PORT="1111"

WORKDIR /workspace

# ── System Dependencies ───────────────────────────────────────────
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
    git git-lfs ffmpeg libgl1 libglib2.0-0 build-essential ninja-build \
    && rm -rf /var/lib/apt/lists/*

# ── PyTorch ───────────────────────────────────────────────────────
RUN /venv/main/bin/pip install torch==2.10.0+cu128 torchvision torchaudio \
    --index-url https://download.pytorch.org/whl/cu128 --quiet

# ── ComfyUI ───────────────────────────────────────────────────────
RUN git clone https://github.com/comfyanonymous/ComfyUI.git /workspace/ComfyUI
RUN /venv/main/bin/pip install -r /workspace/ComfyUI/requirements.txt --quiet

# ── Python Dependencies ───────────────────────────────────────────
RUN /venv/main/bin/pip install \
    "huggingface_hub[cli]" \
    hf_transfer \
    packaging \
    ninja \
    --quiet

# ── Custom Nodes ──────────────────────────────────────────────────
RUN cd /workspace/ComfyUI/custom_nodes && \
    git clone https://github.com/ltdrdata/ComfyUI-Manager --quiet && \
    git clone https://github.com/Lightricks/ComfyUI-LTXVideo --quiet && \
    git clone https://github.com/kijai/ComfyUI-KJNodes --quiet && \
    git clone https://github.com/rgthree/rgthree-comfy --quiet && \
    git clone https://github.com/city96/ComfyUI-GGUF --quiet && \
    git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite --quiet && \
    git clone https://github.com/yolain/ComfyUI-Easy-Use --quiet

RUN for dir in /workspace/ComfyUI/custom_nodes/*/; do \
    if [ -f "$dir/requirements.txt" ]; then \
        /venv/main/bin/pip install -r "$dir/requirements.txt" --quiet || true; \
    fi \
    done

# ── SageAttention3 (SM120 / RTX 5090)
