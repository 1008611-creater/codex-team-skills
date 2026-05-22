from __future__ import annotations

import argparse
import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont


ROOT = Path(r"D:\codex-work\xianyu")
OUT_DIR = ROOT / "output" / "wan22_motion_transfer_pack"
PROMPT_DIR = ROOT / "prompts" / "wan22_motion_transfer"
RAW_DIR = OUT_DIR / "runninghub_raw"
IMG_DIR = OUT_DIR / "images_image2"
RESEARCH_DIR = OUT_DIR / "research"

W = H = 1242
FONT_REG = r"C:\Windows\Fonts\msyh.ttc"
FONT_BOLD = r"C:\Windows\Fonts\msyhbd.ttc"

PROMPTS = {
    "01_cover": """Create a premium square commercial poster background for a Wan2.2 / ComfyUI AI video motion transfer workflow service.

Visual concept:
- a professional video-AI workstation
- central monitor shows an abstract node graph, motion timeline, reference video panels, and output preview panels
- one generic synthetic fashion model silhouette is transferred into a dance / product pose sequence
- make it feel like a real creator workflow, not a fantasy poster

Art direction:
- high-end AI video production studio, cinematic lighting, clean UI mockups
- inspired by premium GPT Image 2 UI/interface and technical infographic cases
- color palette: deep graphite, electric cyan, neon lime accent, warm orange timeline markers
- strong blank space in upper-left and lower-right for Chinese overlay

Strict requirements:
- no readable text, no logos, no watermark
- no celebrity, no public figure, no identifiable real person
- output as polished 1:1 poster, ultra sharp""",
    "02_materials_to_video": """Create a premium 1:1 infographic background showing an AI video workflow from authorized materials to a generated motion-transfer clip.

Composition:
- left: source portrait/photo card and reference action video strip, both generic and non-identifiable
- center: ComfyUI-style node graph and model checkpoint blocks
- right: output video frames with consistent subject pose motion
- include abstract arrows, timeline markers, and quality-check widgets

Style:
- technical product diagram, creator-economy video lab
- white and charcoal surfaces, cyan/lime/orange accents
- leave clean empty bands for Chinese overlay

Strict requirements:
- no readable text, no logos, no watermark
- no celebrity, no unauthorized face likeness""",
    "03_use_cases": """Create a simple four-quadrant AI video workflow board background for a motion-transfer service.

Quadrants:
- dance motion
- fashion showcase
- ecommerce video
- consistency test

Composition:
- each quadrant shows generic non-identifiable synthetic people, video frame strips, motion arrows, and UI panels
- connect quadrants with subtle neon workflow lines
- realistic creator studio feel

Style:
- premium editorial infographic, modern video production UI, polished and clean
- dark-to-light balanced layout, high contrast, not childish
- leave label space in each quadrant

Strict requirements:
- no readable text, no logos, no watermark
- no public figures, no identifiable face""",
    "04_deployment": """Create a premium technical service poster background for deploying a Wan2.2 / ComfyUI AI video workflow.

Composition:
- visual layers for environment check, model files, workflow import, parameter test, sample output
- include a laptop, cloud GPU icon, node graph canvas, file path cards, progress bars
- make it look like a real remote setup and debugging process

Style:
- enterprise AI implementation infographic
- clean dark panels on warm neutral background, cyan and orange accents
- precise spacing and high trust

Strict requirements:
- no readable text, no real brand logos, no watermark
- leave top and bottom blank spaces for later Chinese overlay""",
    "05_packages": """Create a premium three-tier service package poster background for an AI video motion transfer workflow.

Composition:
- three vertical cards on an elegant background
- tiers visually imply: configuration assessment, workflow package, remote setup with one authorized sample clip
- abstract icons for GPU, node graph, model folder, test render, video output
- clear price spaces for post-production Chinese labels

Style:
- Swiss design service menu meets high-end video lab
- dark graphite, white cards, cyan, lime, orange accents
- crisp and print-ready

Strict requirements:
- no readable text, no logos, no watermark""",
    "06_boundary": """Create a clean service boundary and material checklist poster background for an AI video motion transfer service.

Composition:
- two-column board: buyer provides and service delivers
- icons for authorized portrait, reference motion video, GPU/cloud environment, output resolution, test sample, privacy shield
- bottom guardrail band with a shield and lock icon
- professional service terms visual, calm and trustworthy

Style:
- minimal software service infographic, white background, charcoal placeholder blocks, cyan and orange accents
- polished, precise, not cluttered

Strict requirements:
- no readable text, no logos, no watermark
- no public figure imagery
- leave ample blank space for Chinese overlay""",
}


def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(FONT_BOLD if bold else FONT_REG, size=size)


def write_prompts() -> None:
    PROMPT_DIR.mkdir(parents=True, exist_ok=True)
    for name, prompt in PROMPTS.items():
        (PROMPT_DIR / f"{name}.txt").write_text(prompt.strip() + "\n", encoding="utf-8")


def raw_for(name: str) -> Path:
    folder = RAW_DIR / name
    if not folder.exists():
        raise FileNotFoundError(f"Missing RunningHub output folder: {folder}")
    images = sorted(
        [p for p in folder.iterdir() if p.suffix.lower() in {".png", ".jpg", ".jpeg", ".webp"}],
        key=lambda p: p.stat().st_mtime,
    )
    if not images:
        raise FileNotFoundError(f"No image files found in: {folder}")
    return images[-1]


def fit_square(path: Path, darken: float = 0.0, blur: float = 0.0) -> Image.Image:
    im = Image.open(path).convert("RGB")
    scale = max(W / im.width, H / im.height)
    im = im.resize((int(im.width * scale), int(im.height * scale)), Image.Resampling.LANCZOS)
    left = (im.width - W) // 2
    top = (im.height - H) // 2
    im = im.crop((left, top, left + W, top + H))
    if blur:
        im = im.filter(ImageFilter.GaussianBlur(blur))
    if darken:
        im = Image.blend(im, Image.new("RGB", (W, H), (0, 0, 0)), darken)
    return im


def layer(name: str, darken: float = 0.0, blur: float = 0.0):
    img = fit_square(raw_for(name), darken=darken, blur=blur).convert("RGBA")
    return img, ImageDraw.Draw(img)


def save(img: Image.Image, name: str) -> Path:
    IMG_DIR.mkdir(parents=True, exist_ok=True)
    path = IMG_DIR / name
    img.convert("RGB").save(path, quality=95)
    return path


def box(draw: ImageDraw.ImageDraw, xy, fill=(255, 255, 255, 230), radius=30, outline=None, width=2):
    draw.rounded_rectangle(xy, radius=radius, fill=fill, outline=outline, width=width if outline else 1)


def pill(draw: ImageDraw.ImageDraw, xy, text: str, fill, fg=(255, 255, 255), size=28):
    x, y = xy
    f = font(size, True)
    b = draw.textbbox((0, 0), text, font=f)
    tw, th = b[2] - b[0], b[3] - b[1]
    draw.rounded_rectangle((x, y, x + tw + 44, y + th + 28), radius=999, fill=fill)
    draw.text((x + 22, y + 12), text, font=f, fill=fg)


def multiline(draw: ImageDraw.ImageDraw, xy, lines, size=28, fill=(80, 90, 106), gap=13, bold=False):
    x, y = xy
    f = font(size, bold)
    for line in lines:
        draw.text((x, y), line, font=f, fill=fill)
        bbox = draw.textbbox((x, y), line, font=f)
        y = bbox[3] + gap
    return y


def cover() -> Path:
    img, draw = layer("01_cover", darken=0.22)
    box(draw, (58, 64, 944, 590), fill=(8, 14, 22, 228), radius=42, outline=(34, 232, 220, 150))
    pill(draw, (96, 104), "Wan2.2 / ComfyUI / RunningHub", (23, 164, 210, 246), size=27)
    draw.text((94, 178), "AI视频动作迁移", font=font(72, True), fill=(255, 255, 255))
    draw.text((98, 272), "人物替换", font=font(58, True), fill=(255, 255, 255))
    draw.text((98, 348), "工作流跑通", font=font(58, True), fill=(112, 255, 104))
    draw.text((100, 452), "授权素材 / 模型路径 / 报错排查 / 样片测试", font=font(30), fill=(226, 236, 239))

    box(draw, (74, 906, 1168, 1162), fill=(255, 255, 255, 238), radius=36)
    draw.text((116, 944), "8.8 起", font=font(72, True), fill=(20, 24, 32))
    draw.text((372, 966), "评估 / 工作流 / 远程跑通", font=font(34, True), fill=(20, 24, 32))
    draw.text((118, 1054), "适合舞蹈、穿搭、电商短视频、角色一致性测试", font=font(30), fill=(82, 92, 108))
    return save(img, "01_Image2首图_Wan22动作迁移.png")


def materials_to_video() -> Path:
    img, draw = layer("02_materials_to_video", darken=0.05)
    box(draw, (58, 54, 1188, 224), fill=(255, 255, 255, 232), radius=30)
    draw.text((92, 82), "一张图 + 参考动作视频", font=font(52, True), fill=(18, 24, 32))
    draw.text((94, 154), "先看素材是否适配，再跑样片，不盲目承诺", font=font(31), fill=(82, 92, 108))

    items = [("素材", "本人/授权图"), ("动作", "参考视频"), ("工作流", "节点+模型"), ("输出", "样片测试")]
    for i, (title, sub) in enumerate(items):
        x = 84 + i * 288
        y = 888
        box(draw, (x, y, x + 246, y + 158), fill=(255, 255, 255, 236), radius=28)
        draw.text((x + 24, y + 26), title, font=font(34, True), fill=(18, 24, 32))
        draw.text((x + 24, y + 86), sub, font=font(24), fill=(82, 92, 108))

    box(draw, (84, 1072, 1166, 1164), fill=(8, 14, 22, 232), radius=28)
    draw.text((124, 1096), "交付重点：路径表、参数建议、常见报错排查", font=font(30, True), fill=(255, 255, 255))
    return save(img, "02_Image2_素材到视频流程.png")


def use_cases() -> Path:
    img, draw = layer("03_use_cases", darken=0.08)
    box(draw, (58, 54, 1188, 224), fill=(10, 16, 25, 228), radius=30, outline=(112, 255, 104, 120))
    draw.text((92, 82), "四类最容易成交的场景", font=font(50, True), fill=(255, 255, 255))
    draw.text((94, 154), "买家想要的不是概念，是能跑出来的样片", font=font(31), fill=(220, 236, 238))

    cards = [
        ((92, 314), "舞蹈动作", ["参考视频", "姿态迁移", "节奏测试"]),
        ((650, 314), "穿搭展示", ["模特图", "动作套用", "短视频"]),
        ((92, 724), "电商带货", ["商品场景", "口播素材", "批量模板"]),
        ((650, 724), "角色一致", ["多帧一致", "脸部稳定", "重跑建议"]),
    ]
    for (x, y), title, rows in cards:
        box(draw, (x, y, x + 492, y + 184), fill=(255, 255, 255, 234), radius=28)
        draw.text((x + 30, y + 28), title, font=font(38, True), fill=(18, 24, 32))
        draw.text((x + 32, y + 98), " / ".join(rows), font=font(28), fill=(82, 92, 108))

    box(draw, (82, 1050, 1160, 1150), fill=(255, 255, 255, 236), radius=28)
    draw.text((124, 1078), "先做配置评估，素材适配再进入远程跑通", font=font(31, True), fill=(18, 24, 32))
    return save(img, "03_Image2_适用场景.png")


def deployment() -> Path:
    img, draw = layer("04_deployment", darken=0.04)
    box(draw, (58, 54, 1188, 224), fill=(255, 255, 255, 232), radius=30)
    draw.text((92, 82), "部署不是只发文件", font=font(54, True), fill=(18, 24, 32))
    draw.text((94, 154), "模型路径、节点版本、显存设置都要对", font=font(31), fill=(23, 164, 210))

    steps = [("01", "环境检查"), ("02", "模型路径"), ("03", "导入节点"), ("04", "参数测试"), ("05", "样片验收")]
    for i, (num, label) in enumerate(steps):
        x = 84 + i * 220
        y = 878
        box(draw, (x, y, x + 184, y + 150), fill=(255, 255, 255, 236), radius=24)
        draw.text((x + 22, y + 20), num, font=font(28, True), fill=(18, 24, 32))
        draw.text((x + 22, y + 76), label, font=font(26, True), fill=(18, 24, 32))

    box(draw, (84, 1072, 1166, 1164), fill=(8, 14, 22, 232), radius=28)
    draw.text((124, 1096), "可做本地 ComfyUI，也可整理 RunningHub 版本路线", font=font(30, True), fill=(255, 255, 255))
    return save(img, "04_Image2_部署跑通.png")


def packages() -> Path:
    img, draw = layer("05_packages", darken=0.03)
    box(draw, (58, 54, 1188, 214), fill=(255, 255, 255, 232), radius=30)
    draw.text((92, 82), "套餐价格", font=font(54, True), fill=(18, 24, 32))
    draw.text((92, 152), "先评估，再决定是否远程跑通", font=font(31), fill=(82, 92, 108))

    data = [
        ("8.8", "配置评估", ["显卡/云端", "素材建议", "能否跑通"], (23, 164, 210)),
        ("59", "工作流包", ["模型路径", "节点说明", "报错FAQ"], (71, 190, 92)),
        ("299", "远程跑通", ["导入调参", "授权样片", "一轮建议"], (245, 134, 38)),
    ]
    for i, (price, title, rows, color) in enumerate(data):
        x = 78 + i * 386
        box(draw, (x, 320, x + 344, 952), fill=(255, 255, 255, 238), radius=32, outline=color + (180,))
        draw.text((x + 34, 366), price, font=font(76, True), fill=(18, 24, 32))
        draw.text((x + 34, 472), title, font=font(38, True), fill=color)
        multiline(draw, (x + 36, 566), ["· " + row for row in rows], size=28, fill=(82, 92, 108), gap=26)

    box(draw, (84, 1032, 1166, 1148), fill=(8, 14, 22, 232), radius=28)
    draw.text((124, 1062), "主推 299：远程跑通 + 1个授权样片 + 排错说明", font=font(30, True), fill=(255, 255, 255))
    return save(img, "05_Image2_套餐价格.png")


def boundary() -> Path:
    img, draw = layer("06_boundary", darken=0.02)
    box(draw, (58, 54, 1188, 214), fill=(255, 255, 255, 232), radius=30)
    draw.text((92, 82), "素材授权是底线", font=font(54, True), fill=(18, 24, 32))
    draw.text((92, 152), "不接公众人物、不接未授权换脸、不承诺过审", font=font(30), fill=(225, 84, 42))

    box(draw, (88, 300, 590, 768), fill=(255, 255, 255, 234), radius=30)
    draw.text((126, 338), "你提供", font=font(38, True), fill=(18, 24, 32))
    multiline(draw, (130, 418), ["1. 本人/授权图片", "2. 参考动作视频", "3. 显卡或云端环境", "4. 输出时长要求"], size=28)

    box(draw, (650, 300, 1154, 768), fill=(255, 255, 255, 234), radius=30)
    draw.text((688, 338), "我交付", font=font(38, True), fill=(18, 24, 32))
    multiline(draw, (692, 418), ["1. 工作流说明", "2. 模型路径表", "3. 报错排查", "4. 授权样片建议"], size=28)

    box(draw, (88, 836, 1154, 1148), fill=(8, 14, 22, 234), radius=34)
    draw.text((126, 876), "说明", font=font(40, True), fill=(255, 255, 255))
    multiline(
        draw,
        (130, 952),
        ["只接本人或已授权素材", "不做公众人物、未授权换脸、擦边违规", "AI视频稳定性受素材、显卡、模型版本影响"],
        size=28,
        fill=(220, 234, 238),
        gap=18,
    )
    return save(img, "06_Image2_素材要求与边界.png")


def contact_sheet(paths: list[Path]) -> Path:
    thumbs = []
    for path in paths:
        im = Image.open(path).convert("RGB")
        im.thumbnail((360, 360), Image.Resampling.LANCZOS)
        tile = Image.new("RGB", (380, 410), (246, 247, 248))
        tile.paste(im, ((380 - im.width) // 2, 18))
        thumbs.append(tile)
    sheet = Image.new("RGB", (3 * 380, 2 * 410), (232, 235, 238))
    for i, tile in enumerate(thumbs):
        sheet.paste(tile, ((i % 3) * 380, (i // 3) * 410))
    path = IMG_DIR / "image2_contact_sheet.png"
    sheet.save(path, quality=95)
    return path


def write_config(paths: list[Path]) -> None:
    title = "Wan2.2动作迁移｜人物替换视频工作流部署"
    body = """最近 Wan2.2 / ComfyUI 动作迁移很火，但很多人卡在：模型太多、节点版本不对、路径不知道放哪、素材跑出来不稳定。

我这边做的是 AI视频动作迁移 / 人物替换工作流评估与跑通：适合舞蹈动作迁移、穿搭展示、电商短视频、角色一致性测试等场景。

可做：
1. 配置评估：看你的显卡/云端环境、ComfyUI版本、模型路径是否适合跑
2. 工作流整理：提供 Wan2.2 / Animate / ComfyUI 路线说明、模型路径表、节点说明
3. 素材建议：告诉你什么图片和参考视频更容易稳定出片
4. 报错排查：常见缺节点、模型路径、显存爆掉、输出闪烁等问题
5. 远程跑通：在授权素材基础上跑 1 个测试样片，并给参数建议

套餐：
8.8 元：配置评估 + 素材建议
59 元：工作流包 + 模型路径表 + 报错FAQ
299 元：远程跑通 + 1个授权样片 + 一轮参数建议

下单前请先私聊发：
电脑显卡/云端配置、是否已装ComfyUI、想做的视频类型、参考动作视频、本人或已授权人物图片、期望时长和分辨率。

说明：
只接买家本人或已授权素材。
不接公众人物、未授权换脸、擦边违规内容，不承诺平台过审。
AI视频稳定性受素材质量、显卡、模型版本影响，复杂需求需先评估。"""
    config = {
        "title": title,
        "body": body,
        "price": "8.80",
        "originalPrice": "299",
        "noShipping": True,
        "imagePaths": [str(p) for p in paths],
    }
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    (OUT_DIR / "publish_config_wan22_motion_transfer.json").write_text(json.dumps(config, ensure_ascii=False, indent=2), encoding="utf-8")
    (ROOT / "publish_config_wan22_motion_transfer.json").write_text(json.dumps(config, ensure_ascii=False, indent=2), encoding="utf-8")


def write_pack(paths: list[Path]) -> None:
    md = """# Wan2.2 动作迁移工作流上架包

## 标题

Wan2.2动作迁移｜人物替换视频工作流部署

## 核心定位

不是卖一个空泛教程，而是帮买家判断环境、整理工作流、解决模型路径/节点/显存/素材适配问题，主推远程跑通一个授权样片。

## 价格

- 8.8 元：配置评估 + 素材建议
- 59 元：工作流包 + 模型路径表 + 报错FAQ
- 299 元：远程跑通 + 1个授权样片 + 一轮参数建议

## 买家需要提供

显卡/云端配置、ComfyUI安装状态、参考动作视频、本人或已授权人物图片、期望时长和分辨率。

## 边界

只接买家本人或已授权素材；不接公众人物、未授权换脸、擦边违规内容；不承诺平台过审。

## 上架图

"""
    md += "\n".join(f"- {p}" for p in paths)
    md += "\n\n## 类目建议\n\n优先试 `AI提效工具`；如网页端拦截，APP端或 `AI图文工具/服务` 兜底。\n"
    (OUT_DIR / "wan22_motion_transfer_publish_pack.md").write_text(md, encoding="utf-8")


def write_research_note() -> None:
    RESEARCH_DIR.mkdir(parents=True, exist_ok=True)
    note = """# Wan2.2 / ComfyUI 动作迁移需求依据

- Round 4 站内验证: `动作迁移工作流` 关键词下，最高 615 人想要；`Wan2.2+Animate` 方向有 103 人想要；RunningHub 0币动作迁移也有 82 人想要。
- Jina 外部验证: Bilibili `Wan2.2 Animate：动作迁移和角色替换的最佳方案` 捕获 11.6万播放、2153赞、5644收藏。
- 产品化判断: 买家痛点不是“知道这个技术”，而是不会部署、不会放模型、不会调参数、素材不适配。
- 复利资产: 工作流包、模型路径表、报错FAQ、授权样片库、素材要求模板，可持续沉淀。
"""
    (RESEARCH_DIR / "positioning.md").write_text(note, encoding="utf-8")


def build_images() -> list[Path]:
    return [cover(), materials_to_video(), use_cases(), deployment(), packages(), boundary()]


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--prompts-only", action="store_true")
    args = parser.parse_args()

    write_prompts()
    if args.prompts_only:
        print(json.dumps({"promptDir": str(PROMPT_DIR), "prompts": list(PROMPTS.keys())}, ensure_ascii=False, indent=2))
        return

    paths = build_images()
    contact = contact_sheet(paths)
    write_config(paths)
    write_pack(paths)
    write_research_note()
    print(json.dumps({"outDir": str(OUT_DIR), "images": [str(p) for p in paths], "contactSheet": str(contact)}, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
