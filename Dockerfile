#!/bin/bash
set -e

echo "########################################"
echo "#   LTX 2.3 5090 - Provisioning       #"
echo "########################################"

# ── Install dependencies ─────────────────────────────────────────
echo " → Installing dependencies..."
pip install huggingface_hub hf_transfer --quiet

# ── Install SA3 wheel ────────────────────────────────────────────
echo " → Installing SageAttention3..."
pip install https://huggingface.co/ReubenF10/ComfyUI-Models/resolve/main/wheels/ltx/5090/sageattn3-1.0.0-cp312-cp312-linux_x86_64.whl --quiet

# ── Install custom nodes ─────────────────────────────────────────
echo " → Installing custom nodes..."
cd /workspace/ComfyUI/custom_nodes

git clone https://github.com/ltdrdata/ComfyUI-Manager
git clone https://github.com/Lightricks/ComfyUI-LTXVideo
git clone https://github.com/kijai/ComfyUI-KJNodes
git clone https://github.com/rgthree/rgthree-comfy
git clone https://github.com/city96/ComfyUI-GGUF
git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite
git clone https://github.com/yolain/ComfyUI-Easy-Use

for dir in /workspace/ComfyUI/custom_nodes/*/; do
    if [ -f "$dir/requirements.txt" ]; then
        pip install -r "$dir/requirements.txt" --quiet || true
    fi
done

# ── Download models ──────────────────────────────────────────────
echo " → Downloading models..."
export HF_HUB_ENABLE_HF_TRANSFER=1

python3 << PYEOF
import os, shutil
from huggingface_hub import hf_hub_download

token = os.environ["HF_TOKEN"]
base = "/workspace/ComfyUI/models"

models = [
    ("Lightricks/LTX-2.3-fp8", "ltx-2.3-22b-dev-fp8.safetensors",             "checkpoints"),
    ("Lightricks/LTX-2.3",     "ltx-2.3-22b-distilled-lora-384.safetensors",  "loras"),
    ("Lightricks/LTX-2.3",     "ltx-2.3-spatial-upscaler-x2-1.1.safetensors", "latent_upscale_models"),
]

for repo_id, filename, dest_folder in models:
    save_name = filename.split("/")[-1]
    dest = os.path.join(base, dest_folder, save_name)
    if os.path.exists(dest):
        print(f"  ⏭  Already exists: {save_name}")
        continue
    os.makedirs(os.path.join(base, dest_folder), exist_ok=True)
    print(f"  → Downloading: {save_name}")
    path = hf_hub_download(repo_id=repo_id, filename=filename, token=token, local_dir="/tmp/hf_dl", local_dir_use_symlinks=False)
    shutil.move(path, dest)
    print(f"  ✓ Saved: {save_name}")

print("")
print("✓ All models ready")
PYEOF

# ── Restart ComfyUI ──────────────────────────────────────────────
echo " → Restarting ComfyUI..."
supervisorctl restart comfyui

echo ""
echo "✓ Provisioning complete"
