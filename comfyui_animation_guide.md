# Generating Aemeath Animations with ComfyUI

Reference guide for generating additional sprite animations for the Aemeath Desktop Pet.

## Background

- **Existing assets:** 9 GIF animations (200x200px, chibi style, ~9 FPS)
- **Available sprites:** normal, happy_hand_waving, happy_jumping, laugh, laugh_flying, normal_flying, sign, listening_music, seal
- **Needed animations:** fall, drag, sleep, paper_plane_throw, sing, glitch, black cat idle, black cat walk
- **Compatibility note:** The Aemeath LoRA on Civitai uses **Illustrious (SDXL)**, but AnimateDiff is **SD1.5**. This guide covers three paths to work around this.

---

## Path A: AnimateDiff (SD1.5) + IP-Adapter (Proven & Stable)

Uses existing GIF frames as visual reference via IP-Adapter — no Aemeath LoRA needed, the reference image locks the style.

### A1. Custom Nodes to Install

Open ComfyUI Manager → Install by name, then restart ComfyUI:

| Node Pack | Author | Purpose |
|-----------|--------|---------|
| `ComfyUI-AnimateDiff-Evolved` | Kosinkadink | Animation generation |
| `ComfyUI_IPAdapter_plus` | cubiq | Character consistency from reference |
| `ComfyUI-VideoHelperSuite` | Kosinkadink | GIF/video export |
| `ComfyUI-Advanced-ControlNet` | Kosinkadink | Pose control |
| `comfyui_controlnet_aux` | Fannovel16 | OpenPose preprocessing |
| `rembg-comfyui-node` | Jcd1230 | Background removal for transparent sprites |

### A2. Models to Download

| Model | Destination Folder | Source |
|-------|--------------------|--------|
| SD1.5 anime checkpoint (e.g. DreamShaper 8, Anything V5) | `models/checkpoints/` | Civitai |
| `v3_sd15_mm.ckpt` (1.67 GB) | `models/animatediff_models/` | https://huggingface.co/guoyww/animatediff/blob/main/v3_sd15_mm.ckpt |
| `ip-adapter-plus_sd15.safetensors` | `models/ipadapter/` | https://huggingface.co/h94/IP-Adapter/resolve/main/models/ip-adapter-plus_sd15.safetensors |
| `CLIP-ViT-H-14-laion2B-s32B-b79K.safetensors` (3.94 GB) | `models/clip_vision/` | https://huggingface.co/laion/CLIP-ViT-H-14-laion2B-s32B-b79K/blob/main/model.safetensors |
| `control_v11p_sd15_openpose.safetensors` | `models/controlnet/` | https://huggingface.co/lllyasviel/ControlNet-v1-1/tree/main |
| Chibi/pixel LoRA (optional, SD1.5 version) | `models/loras/` | Search Civitai for SD1.5-compatible chibi style LoRAs |

### A3. Workflow (Node Graph)

```
[Load Checkpoint] (SD1.5 anime)
       | MODEL, CLIP, VAE
[Load LoRA] (optional chibi style, strength 0.6-0.8)
       | MODEL
[IPAdapter Unified Loader] (preset: PLUS SD15)
       | IPADAPTER, CLIP_VISION
[IPAdapter Apply]
  |- MODEL from above
  |- IMAGE from [Load Image] <-- upload one frame from existing Aemeath GIF
  |- IPADAPTER + CLIP_VISION from Unified Loader
  |- weight: 0.7-0.8
       | MODEL (now style-locked to Aemeath)
[Apply AnimateDiff Model]
  |- motion_model: v3_sd15_mm.ckpt
  |- context_length: 16
  |- beta_schedule: sqrt_linear
       | MODEL
[KSampler]
  |- MODEL from above
  |- positive: [CLIP Text Encode] -> prompt (see A5)
  |- negative: [CLIP Text Encode] -> "realistic, blurry, low quality, watermark, text, bad anatomy"
  |- latent: [Empty Latent Image] -> 512x512, batch_size: 16
  |- steps: 30, cfg: 8, sampler: euler_ancestral, scheduler: karras, denoise: 1.0
       | LATENT
[VAE Decode]
       | IMAGE (16 frames)
[Image Remove Background (Rembg)]
       | IMAGE (transparent)
[Video Combine] (VHS_VideoCombine)
  |- frame_rate: 9
  |- format: image/gif
       -> OUTPUT: animated GIF
```

### A4. Key Parameters

| Parameter | Value | Notes |
|-----------|-------|-------|
| Resolution | 512x512 | AnimateDiff native training size |
| Batch size (frames) | 16 | Increase to 24 for longer animations |
| Context length | 16 | Sweet spot for v3 motion module |
| Context overlap | 4 | Smoother transitions between context windows |
| Steps | 25-35 | Higher = better quality |
| CFG | 7-9 | |
| Sampler | euler_ancestral | Best for AnimateDiff |
| IP-Adapter weight | 0.7-0.8 | Too high = stiff; too low = off-model |
| Denoise | 1.0 (txt2vid) or 0.7-0.85 (img2vid) | Lower denoise preserves reference more |

### A5. Prompts Per Animation

Base style tokens: `chibi, 1girl, pink hair, white background, full body`

| Animation | Prompt additions |
|-----------|-----------------|
| `fall` | falling, arms up, surprised expression |
| `drag` | being held up, dangling, surprised |
| `sleep` | sleeping, eyes closed, curled up, peaceful |
| `paper_plane_throw` | throwing paper airplane |
| `sing` | singing, holding microphone, music notes |
| `glitch` | Generate normal idle, apply glitch in post-processing |
| `black_cat_idle` | chibi, black cat, sitting, amber eyes, tail swaying, white background |
| `black_cat_walk` | chibi, black cat, walking, amber eyes, white background |

---

## Path B: WAN 2.2 (SDXL-Native) — Use Aemeath LoRA Directly

WAN 2.2 is a video generation model that natively supports SDXL/Illustrious, so the Aemeath LoRA works here.

### B1. Requirements

- **VRAM:** Minimum 12 GB, recommended 16+ GB
- WAN 2.2 nodes are built into recent ComfyUI (no custom nodes needed)
- Install `ComfyUI-VideoHelperSuite` for GIF export

### B2. Models to Download

| Model | Source |
|-------|--------|
| WAN 2.2 5B I2V (Image-to-Video) | https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged |
| Illustrious XL checkpoint | https://civitai.com/models/827184/wai-illustrious-sdxl |
| Aemeath LoRA v1.5 | https://civitai.com/models/2196660/aimis-wuthering-waves (weight 0.8) |

### B3. Workflow

1. In ComfyUI: **Menu -> Workflow -> Browse Templates -> Video -> "Wan2.2 I2V"**
2. Connect Illustrious checkpoint + Aemeath LoRA
3. Generate a **static frame** of the desired pose using txt2img first
4. Feed that frame into WAN 2.2 I2V as starting image
5. Describe the motion in the prompt: "chibi girl sleeping, gentle breathing, eyes closed"
6. Export with `Video Combine` at 9 FPS as GIF

---

## Path C: Hybrid (Recommended for Best Results)

1. **Generate static keyframes** using Illustrious + Aemeath LoRA (SDXL txt2img) — perfect character accuracy
2. **Animate those frames** using either:
   - AnimateDiff SD1.5 + IP-Adapter (feed static frame as reference, denoise 0.7-0.85)
   - WAN 2.2 I2V (if you have 12+ GB VRAM)
3. **Post-process:** resize to 200x200, remove background, adjust to 9 FPS

---

## Pre-Built Workflows

Drag these directly into ComfyUI, then click **Manager -> Install Missing Custom Nodes -> Restart**:

| Workflow | URL |
|----------|-----|
| AnimateDiff + IP-Adapter img2vid | https://civitai.com/articles/4339 |
| Sprite Sheet Maker v H42 | https://civitai.com/models/448101/sprite-sheet-maker |
| Easy Sprite Animation v1.0 | https://openart.ai/workflows/espral/easy-sprite-animation-v10-by-dragon-espral/OhQqtBaR6uFevZLNK5gP |
| WAN 2.2 I2V (official) | Built into ComfyUI templates |

---

## Expected Folder Structure

```
ComfyUI/
  models/
    checkpoints/
      illustrious_xl.safetensors        (SDXL, Path B/C)
      dreamshaper_8.safetensors          (SD1.5, Path A)
    loras/
      aimis_aemeath_v1.5.safetensors     (Aemeath character, SDXL)
      chibi_pixel_art.safetensors        (style LoRA, optional)
    animatediff_models/
      v3_sd15_mm.ckpt                    (AnimateDiff motion module)
    ipadapter/
      ip-adapter-plus_sd15.safetensors
    clip_vision/
      CLIP-ViT-H-14-laion2B-s32B-b79K.safetensors
    controlnet/
      control_v11p_sd15_openpose.safetensors
  custom_nodes/
    ComfyUI-AnimateDiff-Evolved/
    ComfyUI_IPAdapter_plus/
    ComfyUI-VideoHelperSuite/
    ComfyUI-Advanced-ControlNet/
    comfyui_controlnet_aux/
    rembg-comfyui-node/
```

---

## Post-Processing Checklist

1. **Resize** from 512x512 to 200x200 (bilinear to match existing GIF quality)
2. **Remove background** if not already transparent (Rembg node or manual in Aseprite)
3. **Adjust frame rate** to 9 FPS to match existing animations
4. **Touch up** any off-model frames in Aseprite
5. **Glitch effect** — apply digitally in code or Aseprite (RGB split, scanlines, flicker) rather than generating

---

## Quick Start (Try First)

1. Download `v3_sd15_mm.ckpt`, `ip-adapter-plus_sd15.safetensors`, and `CLIP-ViT-H-14` model
2. Install the 6 custom node packs from Path A
3. Download the workflow from https://civitai.com/articles/4339 and drag into ComfyUI
4. Set checkpoint to any SD1.5 anime model you have
5. Upload one frame from `normal.gif` as the IP-Adapter reference image
6. Set prompt to describe the animation (e.g. "chibi girl sleeping")
7. Set batch_size=16, frame_rate=9
8. Queue Prompt and iterate on IP-Adapter weight, prompt, and steps
