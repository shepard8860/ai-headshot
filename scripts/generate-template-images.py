#!/usr/bin/env python3
# ============================================================
# AI职业形象照 - 模板底图批量生成脚本
# 用法: python3 scripts/generate-template-images.py
# 说明: 读取 design/templates/ 下的JSON配置，调用AI图片生成API
#       批量生成28张高质量职业照底图（无人脸，供后续用户自拍融合）
# ============================================================

import json
import os
import sys
import time
import argparse
import urllib.request
from pathlib import Path
from typing import List, Dict, Any, Optional

# --------------------------------------------------
# 配置区域（请根据你的环境修改）
# --------------------------------------------------

# 输出目录
OUTPUT_DIR = Path(__file__).parent.parent / "design" / "template-images"
# 模板JSON目录
TEMPLATES_DIR = Path(__file__).parent.parent / "design" / "templates"
# 进度文件（断点续传）
PROGRESS_FILE = Path(__file__).parent.parent / "design" / ".generate-progress.json"

# 选择使用的API: "replicate" | "stability" | "webui"
API_PROVIDER = os.environ.get("API_PROVIDER", "replicate")

# Replicate API 配置
REPLICATE_API_TOKEN = os.environ.get("REPLICATE_API_TOKEN", "")
REPLICATE_MODEL = os.environ.get("REPLICATE_MODEL", "black-forest-labs/flux-schnell")
# REPLICATE_MODEL = "stability-ai/stable-diffusion-3"

# Stability AI API 配置
STABILITY_API_KEY = os.environ.get("STABILITY_API_KEY", "")
STABILITY_ENGINE = os.environ.get("STABILITY_ENGINE", "stable-diffusion-xl-1024-v1-0")

# Stable Diffusion WebUI (AUTOMATIC1111 / Forge) 配置
WEBUI_URL = os.environ.get("WEBUI_URL", "http://127.0.0.1:7860")

# 生成参数
IMAGE_WIDTH = int(os.environ.get("IMAGE_WIDTH", "1024"))
IMAGE_HEIGHT = int(os.environ.get("IMAGE_HEIGHT", "1024"))
SEED = int(os.environ.get("SEED", "-1"))  # -1 表示随机
NEGATIVE_PROMPT = (
    "face, facial features, eyes, nose, mouth, lips, teeth, eyebrows, "
    "portrait of a person with visible face, head facing camera, "
    "ugly, deformed, blurry, low quality, oversaturated"
)

# 请求间隔（秒），防止触发限流
REQUEST_DELAY = float(os.environ.get("REQUEST_DELAY", "2.0"))

# --------------------------------------------------
# Prompt 构建
# --------------------------------------------------

FACELESS_MODIFIER = (
    "The subject's face is completely turned away from the camera or obscured, "
    "NO facial features visible at all (no eyes, nose, mouth), "
    "smooth blank skin or hair covering where the face would be, "
    "head facing backward or looking away, "
    "upper body and clothing clearly visible, professional photography. "
)


def build_prompt(template: Dict[str, Any]) -> str:
    """组合模板JSON中的prompt为完整生成prompt"""
    parts = [
        template.get("style_prompt", ""),
        template.get("background_prompt", ""),
        template.get("clothing_prompt", ""),
        template.get("lighting_prompt", ""),
        FACELESS_MODIFIER,
        f"Color tone: {template.get('color_tone', 'natural')}",
    ]
    # 清理并组合
    prompt = ", ".join(p.strip() for p in parts if p.strip())
    # 加入通用质量后缀
    quality_suffix = (
        ", professional studio photography, 8k uhd, sharp focus, "
        "clean composition, solid or gradient background, "
        "high-end retouching, magazine quality"
    )
    return prompt + quality_suffix


# --------------------------------------------------
# API 调用实现
# --------------------------------------------------

def call_replicate(prompt: str, output_path: Path, width: int = 1024, height: int = 1024) -> bool:
    """调用 Replicate API 生成图片"""
    if not REPLICATE_API_TOKEN:
        print("[ERR] REPLICATE_API_TOKEN 未设置")
        return False

    headers = {
        "Authorization": f"Token {REPLICATE_API_TOKEN}",
        "Content-Type": "application/json",
    }

    # 构建请求体（不同模型参数略有差异，这里以 flux-schnell 为例）
    payload = {
        "version": REPLICATE_MODEL,  # 对于官方模型通常不需要version
        "input": {
            "prompt": prompt,
            "aspect_ratio": f"{width}:{height}",
            "output_format": "jpg",
            "output_quality": 95,
        },
    }

    # flux-schnell 不需要 version 字段，使用模型路径
    if "/" in REPLICATE_MODEL:
        # 使用模型部署路径创建预测
        create_url = f"https://api.replicate.com/v1/models/{REPLICATE_MODEL}/predictions"
        payload.pop("version", None)
    else:
        create_url = "https://api.replicate.com/v1/predictions"

    req = urllib.request.Request(
        create_url,
        data=json.dumps(payload).encode("utf-8"),
        headers=headers,
        method="POST",
    )

    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            result = json.loads(resp.read().decode("utf-8"))
    except Exception as e:
        print(f"[ERR] Replicate 创建任务失败: {e}")
        return False

    prediction_id = result.get("id")
    if not prediction_id:
        print(f"[ERR] Replicate 未返回 prediction id: {result}")
        return False

    print(f"      任务ID: {prediction_id}，轮询结果中...")

    # 轮询结果
    poll_url = f"https://api.replicate.com/v1/predictions/{prediction_id}"
    max_retries = 120
    for i in range(max_retries):
        time.sleep(2)
        poll_req = urllib.request.Request(poll_url, headers=headers)
        try:
            with urllib.request.urlopen(poll_req, timeout=30) as resp:
                poll_result = json.loads(resp.read().decode("utf-8"))
        except Exception as e:
            print(f"      轮询异常: {e}")
            continue

        status = poll_result.get("status")
        if status == "succeeded":
            output_url = poll_result.get("output")
            # flux-schnell 返回的是字符串URL
            if isinstance(output_url, list) and len(output_url) > 0:
                output_url = output_url[0]
            if not output_url or not isinstance(output_url, str):
                print(f"[ERR] 未获取到有效输出URL: {poll_result}")
                return False
            return download_image(output_url, output_path)
        elif status in ("failed", "canceled"):
            print(f"[ERR] 任务失败或取消: {poll_result.get('error')}")
            return False
        else:
            print(f"      状态: {status} ({i+1}/{max_retries})")

    print("[ERR] 轮询超时")
    return False


def call_stability(prompt: str, output_path: Path, width: int = 1024, height: int = 1024) -> bool:
    """调用 Stability AI API 生成图片"""
    if not STABILITY_API_KEY:
        print("[ERR] STABILITY_API_KEY 未设置")
        return False

    url = f"https://api.stability.ai/v1/generation/{STABILITY_ENGINE}/text-to-image"
    headers = {
        "Authorization": f"Bearer {STABILITY_API_KEY}",
        "Content-Type": "application/json",
    }
    payload = {
        "text_prompts": [{"text": prompt, "weight": 1.0}],
        "cfg_scale": 7,
        "height": height,
        "width": width,
        "samples": 1,
        "steps": 30,
        "seed": SEED if SEED >= 0 else None,
    }
    if payload["seed"] is None:
        payload.pop("seed")

    req = urllib.request.Request(url, data=json.dumps(payload).encode("utf-8"), headers=headers)
    try:
        with urllib.request.urlopen(req, timeout=120) as resp:
            result = json.loads(resp.read().decode("utf-8"))
    except Exception as e:
        print(f"[ERR] Stability API 调用失败: {e}")
        return False

    artifacts = result.get("artifacts", [])
    if not artifacts:
        print("[ERR] Stability API 未返回图片")
        return False

    import base64
    img_data = base64.b64decode(artifacts[0]["base64"])
    output_path.write_bytes(img_data)
    return True


def call_webui(prompt: str, output_path: Path, width: int = 1024, height: int = 1024) -> bool:
    """调用本地 Stable Diffusion WebUI API 生成图片"""
    url = f"{WEBUI_URL}/sdapi/v1/txt2img"
    payload = {
        "prompt": prompt,
        "negative_prompt": NEGATIVE_PROMPT,
        "width": width,
        "height": height,
        "steps": 30,
        "cfg_scale": 7,
        "sampler_name": "DPM++ 2M Karras",
        "batch_size": 1,
        "n_iter": 1,
        "seed": SEED if SEED >= 0 else -1,
    }
    req = urllib.request.Request(url, data=json.dumps(payload).encode("utf-8"), headers={"Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=120) as resp:
            result = json.loads(resp.read().decode("utf-8"))
    except Exception as e:
        print(f"[ERR] WebUI API 调用失败: {e}")
        return False

    images = result.get("images", [])
    if not images:
        print("[ERR] WebUI 未返回图片")
        return False

    import base64
    img_data = base64.b64decode(images[0].split(",")[0])
    output_path.write_bytes(img_data)
    return True


def download_image(url: str, output_path: Path) -> bool:
    """下载图片到本地"""
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req, timeout=120) as resp:
            output_path.write_bytes(resp.read())
        return True
    except Exception as e:
        print(f"[ERR] 下载图片失败: {e}")
        return False


# --------------------------------------------------
# 进度管理（断点续传）
# --------------------------------------------------

def load_progress() -> Dict[str, Any]:
    """加载已生成进度"""
    if PROGRESS_FILE.exists():
        try:
            return json.loads(PROGRESS_FILE.read_text(encoding="utf-8"))
        except Exception:
            pass
    return {"completed": [], "failed": []}


def save_progress(progress: Dict[str, Any]):
    """保存生成进度"""
    PROGRESS_FILE.write_text(json.dumps(progress, indent=2, ensure_ascii=False), encoding="utf-8")


# --------------------------------------------------
# 主流程
# --------------------------------------------------

def load_templates() -> List[Dict[str, Any]]:
    """加载所有模板JSON文件"""
    templates = []
    if not TEMPLATES_DIR.exists():
        print(f"[ERR] 模板目录不存在: {TEMPLATES_DIR}")
        sys.exit(1)

    for json_file in sorted(TEMPLATES_DIR.glob("*.json")):
        try:
            data = json.loads(json_file.read_text(encoding="utf-8"))
            if isinstance(data, list):
                templates.extend(data)
            else:
                templates.append(data)
        except Exception as e:
            print(f"[WARN] 读取模板文件失败 {json_file.name}: {e}")

    # 去重并排序
    seen = set()
    unique = []
    for t in templates:
        tid = t.get("id")
        if tid and tid not in seen:
            seen.add(tid)
            unique.append(t)
    unique.sort(key=lambda x: (x.get("category_id", ""), x.get("sort_order", 0)))
    return unique


def generate_image(template: Dict[str, Any], provider: str) -> bool:
    """为单个模板生成图片"""
    template_id = template["id"]
    output_path = OUTPUT_DIR / f"{template_id}.jpg"

    prompt = build_prompt(template)
    print(f"\n  Prompt ({len(prompt)} chars):")
    print(f"    {prompt[:200]}...")

    if provider == "replicate":
        return call_replicate(prompt, output_path, IMAGE_WIDTH, IMAGE_HEIGHT)
    elif provider == "stability":
        return call_stability(prompt, output_path, IMAGE_WIDTH, IMAGE_HEIGHT)
    elif provider == "webui":
        return call_webui(prompt, output_path, IMAGE_WIDTH, IMAGE_HEIGHT)
    else:
        print(f"[ERR] 不支持的 API_PROVIDER: {provider}")
        return False


def main():
    parser = argparse.ArgumentParser(description="AI职业形象照模板底图批量生成")
    parser.add_argument("--provider", choices=["replicate", "stability", "webui"], default=API_PROVIDER,
                        help="选择API提供商")
    parser.add_argument("--width", type=int, default=IMAGE_WIDTH, help="图片宽度")
    parser.add_argument("--height", type=int, default=IMAGE_HEIGHT, help="图片高度")
    parser.add_argument("--delay", type=float, default=REQUEST_DELAY, help="请求间隔秒数")
    parser.add_argument("--dry-run", action="store_true", help="仅打印prompt，不实际调用API")
    parser.add_argument("--retry-failed", action="store_true", help="重试之前失败的模板")
    parser.add_argument("--template-id", type=str, default=None, help="仅生成指定模板ID")
    args = parser.parse_args()

    # 创建输出目录
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    templates = load_templates()
    print(f"[INFO] 共加载 {len(templates)} 个模板")

    progress = load_progress()
    completed = set(progress.get("completed", []))
    failed = set(progress.get("failed", []))

    # 如果指定了模板ID
    if args.template_id:
        templates = [t for t in templates if t.get("id") == args.template_id]
        if not templates:
            print(f"[ERR] 未找到模板: {args.template_id}")
            sys.exit(1)
        # 强制重新生成
        completed.discard(args.template_id)
        failed.discard(args.template_id)

    # 过滤已完成的（除非重试失败）
    to_generate = []
    for t in templates:
        tid = t["id"]
        if tid in completed:
            continue
        if tid in failed and not args.retry_failed:
            continue
        to_generate.append(t)

    print(f"[INFO] 待生成: {len(to_generate)} 个（已完成: {len(completed)}, 失败: {len(failed)}）")

    if args.dry_run:
        print("\n========== DRY RUN 模式 ==========")
        for t in to_generate:
            print(f"\n--- {t['id']} | {t['name']} ---")
            print(build_prompt(t))
        return

    # 检查API配置
    if args.provider == "replicate" and not REPLICATE_API_TOKEN:
        print("[ERR] 请设置环境变量 REPLICATE_API_TOKEN")
        sys.exit(1)
    if args.provider == "stability" and not STABILITY_API_KEY:
        print("[ERR] 请设置环境变量 STABILITY_API_KEY")
        sys.exit(1)

    success_count = 0
    fail_count = 0

    for idx, template in enumerate(to_generate, 1):
        tid = template["id"]
        name = template.get("name", "")
        print(f"\n[{idx}/{len(to_generate)}] 生成: {tid} | {name}")
        print(f"      输出: {OUTPUT_DIR / f'{tid}.jpg'}")

        ok = generate_image(template, args.provider)
        if ok:
            print(f"      [OK] 成功")
            completed.add(tid)
            failed.discard(tid)
            success_count += 1
        else:
            print(f"      [FAIL] 失败")
            failed.add(tid)
            fail_count += 1

        progress["completed"] = sorted(list(completed))
        progress["failed"] = sorted(list(failed))
        save_progress(progress)

        if idx < len(to_generate):
            print(f"      等待 {args.delay} 秒...")
            time.sleep(args.delay)

    print(f"\n========== 生成完成 ==========")
    print(f"成功: {success_count} | 失败: {fail_count}")
    print(f"输出目录: {OUTPUT_DIR}")
    print(f"进度文件: {PROGRESS_FILE}")


if __name__ == "__main__":
    main()
