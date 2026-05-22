from __future__ import annotations

import argparse
import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont


ROOT = Path(r"D:\codex-work\xianyu")
OUT_DIR = ROOT / "output" / "male_presence_pack"
PROMPT_DIR = ROOT / "prompts" / "male_presence"
RAW_DIR = OUT_DIR / "runninghub_raw"
IMG_DIR = OUT_DIR / "images_image2"
RESEARCH_DIR = OUT_DIR / "research"

W = H = 1242
FONT_REG = r"C:\Windows\Fonts\msyh.ttc"
FONT_BOLD = r"C:\Windows\Fonts\msyhbd.ttc"

PROMPTS = {
    "01_cover": """Create a premium square commercial poster background for an AI male presence / social profile portrait service.

Visual concept:
- a modern lifestyle content workspace with a synthetic young man shown in multiple premium scene cards
- central screen displays travel, basketball, and business portrait outputs as a curated set
- the result should feel like a real personal branding or display-photo service, not a playful meme

Art direction:
- inspired by premium GPT Image 2 ecommerce and editorial infographic cases
- polished, high-trust, clean layout, subtle cinematic lighting
- color palette: ivory, graphite, muted blue, black, warm gold accent
- strong blank space in upper-left and lower-right for Chinese overlay

Strict requirements:
- no readable text, no logos, no watermark
- no celebrity, no public figure, no identifiable real person
- output as polished 1:1 poster, ultra sharp""",
    "02_travel": """Create a high-end square infographic background showing a young man's travel-style portrait workflow.

Composition:
- left: reference face card and pose/style notes
- center: transformation pipeline and scene cards
- right: a premium travel portrait scene with a young man in a city or coastal location
- make it look like a real social photo set, not fantasy art

Style:
- premium editorial portrait board, clean studio to lifestyle transition
- ivory, cool blue, charcoal, subtle gold accent
- leave empty areas for later Chinese overlay

Strict requirements:
- no readable text, no logos, no watermark
- no identifiable person or public figure""",
    "03_basketball": """Create a high-end square infographic background showing a sports-capture style portrait of a young man at a basketball game.

Composition:
- left: reference portrait and style cards
- center: camera capture workflow and frame strips
- right: candid basketball arena scene with a young man as the subject
- make it feel like a realistic captured display photo, not a poster

Style:
- premium social media portrait board, dynamic but believable, high clarity
- dark arena tones with controlled warm highlights
- leave clean blank area for later Chinese overlay

Strict requirements:
- no readable text, no logos, no watermark
- no public figure, no celebrity, no identifiable real person""",
    "04_business": """Create a premium business portrait background for an AI male headshot service.

Composition:
- a confident young man in a clean business portrait scene
- include cards for lighting, background, outfit, and crop styles
- the composition should feel like a real headshot or display-photo service

Style:
- professional studio portrait, editorial commerce, crisp and trustworthy
- ivory, graphite, deep navy, gold accent
- leave space for Chinese labels

Strict requirements:
- no readable text, no logos, no watermark
- no public figure, no celebrity, no identifiable real person""",
    "05_packages": """Create a premium three-tier service menu background for an AI male presence portrait service.

Composition:
- three vertical cards on an elegant background
- tiers visually imply: test portrait, display set, full presence package
- include abstract icons for face reference, scene selection, business portrait, travel portrait, sports portrait
- clear price spaces for later Chinese overlay

Style:
- luxury service menu, clean editorial layout, premium and restrained
- ivory, charcoal, muted blue, warm gold
- sharp and readable structure

Strict requirements:
- no readable text, no logos, no watermark""",
    "06_boundary": """Create a clean trust-and-boundary checklist poster background for an AI male presence service.

Composition:
- two-column board: buyer provides and service delivers
- icons for own face photo, style reference, scene choice, output size, revision, privacy shield
- bottom guardrail band with shield icon
- calm and professional

Style:
- minimal fashion-service infographic, white background, charcoal placeholder blocks, muted blue and gold accents
- polished and precise

Strict requirements:
- no readable text, no logos, no watermark
- no public figures, no identifiable real people""",
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
    img, draw = layer("01_cover", darken=0.18)
    box(draw, (58, 64, 948, 588), fill=(10, 12, 18, 228), radius=42, outline=(97, 140, 224, 150))
    pill(draw, (96, 104), "男生展示面 / 朋友圈 / 头像", (97, 140, 224, 246), size=27)
    draw.text((94, 178), "男生展示面AI套图", font=font(70, True), fill=(255, 255, 255))
    draw.text((98, 272), "旅行 / 球场 / 商务", font=font(56, True), fill=(255, 255, 255))
    draw.text((98, 346), "三场景", font=font(56, True), fill=(97, 140, 224))
    draw.text((100, 450), "朋友圈帅照 / 社交头像 / 展示面定制", font=font(30), fill=(226, 236, 239))

    box(draw, (74, 906, 1168, 1162), fill=(255, 255, 255, 238), radius=36)
    draw.text((116, 944), "9.9 起", font=font(72, True), fill=(20, 24, 32))
    draw.text((372, 966), "测试 / 套图 / 展示面包", font=font(34, True), fill=(20, 24, 32))
    draw.text((118, 1054), "适合想发朋友圈、做头像、做展示面的男生", font=font(30), fill=(82, 92, 108))
    return save(img, "01_Image2首图_男生展示面AI套图.png")


def travel() -> Path:
    img, draw = layer("02_travel", darken=0.03)
    box(draw, (58, 54, 1188, 224), fill=(255, 255, 255, 232), radius=30)
    draw.text((92, 82), "旅行场景", font=font(52, True), fill=(18, 24, 32))
    draw.text((94, 154), "让头像看起来像真的去过地方", font=font(31), fill=(82, 92, 108))

    items = [("脸型", "清晰正脸"), ("风格", "旅拍感"), ("场景", "海边/城市"), ("输出", "朋友圈图")]
    for i, (title, sub) in enumerate(items):
        x = 84 + i * 288
        y = 888
        box(draw, (x, y, x + 246, y + 158), fill=(255, 255, 255, 236), radius=28)
        draw.text((x + 24, y + 26), title, font=font(34, True), fill=(18, 24, 32))
        draw.text((x + 24, y + 86), sub, font=font(24), fill=(82, 92, 108))

    box(draw, (84, 1072, 1166, 1164), fill=(10, 12, 18, 232), radius=28)
    draw.text((124, 1096), "重点是人感，不是把脸硬贴到风景上", font=font(30, True), fill=(255, 255, 255))
    return save(img, "02_Image2_旅行场景.png")


def basketball() -> Path:
    img, draw = layer("03_basketball", darken=0.05)
    box(draw, (58, 54, 1188, 224), fill=(255, 255, 255, 232), radius=30)
    draw.text((92, 82), "球场抓拍感", font=font(52, True), fill=(18, 24, 32))
    draw.text((94, 154), "适合发朋友圈和小红书展示面", font=font(31), fill=(97, 140, 224))

    items = [("脸型", "稳定五官"), ("风格", "球场氛围"), ("动作", "抓拍感"), ("输出", "社媒发图")]
    for i, (title, sub) in enumerate(items):
        x = 84 + i * 288
        y = 888
        box(draw, (x, y, x + 246, y + 158), fill=(255, 255, 255, 236), radius=28)
        draw.text((x + 24, y + 26), title, font=font(34, True), fill=(18, 24, 32))
        draw.text((x + 24, y + 86), sub, font=font(24), fill=(82, 92, 108))

    box(draw, (84, 1072, 1166, 1164), fill=(10, 12, 18, 232), radius=28)
    draw.text((124, 1096), "更像现场抓拍，而不是摆拍模板", font=font(30, True), fill=(255, 255, 255))
    return save(img, "03_Image2_球场抓拍感.png")


def business() -> Path:
    img, draw = layer("04_business", darken=0.03)
    box(draw, (58, 54, 1188, 224), fill=(255, 255, 255, 232), radius=30)
    draw.text((92, 82), "商务形象照", font=font(52, True), fill=(18, 24, 32))
    draw.text((94, 154), "简历头像、朋友圈头像、商务展示面", font=font(31), fill=(82, 92, 108))

    items = [("脸型", "正脸稳定"), ("风格", "商务感"), ("背景", "干净专业"), ("输出", "头像裁切")]
    for i, (title, sub) in enumerate(items):
        x = 84 + i * 288
        y = 888
        box(draw, (x, y, x + 246, y + 158), fill=(255, 255, 255, 236), radius=28)
        draw.text((x + 24, y + 26), title, font=font(34, True), fill=(18, 24, 32))
        draw.text((x + 24, y + 86), sub, font=font(24), fill=(82, 92, 108))

    box(draw, (84, 1072, 1166, 1164), fill=(10, 12, 18, 232), radius=28)
    draw.text((124, 1096), "适合求职、社交、朋友圈头像升级", font=font(30, True), fill=(255, 255, 255))
    return save(img, "04_Image2_商务形象照.png")


def packages() -> Path:
    img, draw = layer("05_packages", darken=0.03)
    box(draw, (58, 54, 1188, 214), fill=(255, 255, 255, 232), radius=30)
    draw.text((92, 82), "套餐价格", font=font(54, True), fill=(18, 24, 32))
    draw.text((92, 152), "低价测试到完整展示面包", font=font(31), fill=(82, 92, 108))

    data = [
        ("9.9", "单图测试", ["1张效果图", "风格建议", "是否可做"], (97, 140, 224)),
        ("29", "4图套装", ["旅行/球场", "商务/头像", "社媒发图"], (245, 134, 38)),
        ("99", "展示面包", ["12张风格图", "头像裁切", "复用建议"], (71, 190, 92)),
    ]
    for i, (price, title, rows, color) in enumerate(data):
        x = 78 + i * 386
        box(draw, (x, 320, x + 344, 952), fill=(255, 255, 255, 238), radius=32, outline=color + (180,))
        draw.text((x + 34, 366), price, font=font(76, True), fill=(18, 24, 32))
        draw.text((x + 34, 472), title, font=font(38, True), fill=color)
        multiline(draw, (x + 36, 566), ["· " + row for row in rows], size=28, fill=(82, 92, 108), gap=26)

    box(draw, (84, 1032, 1166, 1148), fill=(10, 12, 18, 232), radius=28)
    draw.text((124, 1062), "主推 99：一套可持续发图的展示面风格图", font=font(30, True), fill=(255, 255, 255))
    return save(img, "05_Image2_套餐价格.png")


def boundary() -> Path:
    img, draw = layer("06_boundary", darken=0.02)
    box(draw, (58, 54, 1188, 214), fill=(255, 255, 255, 232), radius=30)
    draw.text((92, 82), "边界先说清", font=font(54, True), fill=(18, 24, 32))
    draw.text((92, 152), "只接本人或授权照片", font=font(31), fill=(224, 134, 38))

    box(draw, (88, 300, 590, 768), fill=(255, 255, 255, 234), radius=30)
    draw.text((126, 338), "你提供", font=font(38, True), fill=(18, 24, 32))
    multiline(draw, (130, 418), ["1. 清晰正脸照", "2. 想要的场景", "3. 风格参考", "4. 输出尺寸"], size=28)

    box(draw, (650, 300, 1154, 768), fill=(255, 255, 255, 234), radius=30)
    draw.text((688, 338), "我交付", font=font(38, True), fill=(18, 24, 32))
    multiline(draw, (692, 418), ["1. 旅行图", "2. 球场图", "3. 商务图", "4. 头像裁切"], size=28)

    box(draw, (88, 836, 1154, 1148), fill=(10, 12, 18, 234), radius=34)
    draw.text((126, 876), "说明", font=font(40, True), fill=(255, 255, 255))
    multiline(
        draw,
        (130, 952),
        ["不接未授权明星照", "不承诺平台过审和效果完全一致", "复杂姿态和强反光场景需要先测试"],
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
    title = "男生展示面AI套图｜旅行/球场/商务三场景"
    body = """很多男生想要的不是“精修头像”，而是一套能发朋友圈、做头像、做展示面的内容。

我这边做的是 男生展示面AI套图：围绕你的正脸照和想要的风格，做旅行、球场、商务三类内容，适合朋友圈、小红书、社交头像、简历头像升级。

可做：
1. 旅行图：海边、城市、街拍感展示面
2. 球场图：韩国球赛/篮球赛这种抓拍感风格
3. 商务图：简历头像、求职头像、商务展示面
4. 头像裁切：适合直接发社交平台
5. 展示面包：多张风格图，方便后续复用

套餐：
9.9 元：单图测试 + 风格建议
29 元：4图套装（旅行/球场/商务/头像）
99 元：12张展示面包 + 裁切建议

下单前请先私聊发：
清晰正脸照、想要的场景、风格参考、输出尺寸、是否要头像裁切。

说明：
只接本人或授权照片。
不接未授权明星照。
不承诺平台过审和效果完全一致，复杂姿态和强反光场景需要先测试。"""
    config = {
        "title": title,
        "body": body,
        "price": "9.90",
        "originalPrice": "99",
        "noShipping": True,
        "imagePaths": [str(p) for p in paths],
    }
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    (OUT_DIR / "publish_config_male_presence.json").write_text(json.dumps(config, ensure_ascii=False, indent=2), encoding="utf-8")
    (ROOT / "publish_config_male_presence.json").write_text(json.dumps(config, ensure_ascii=False, indent=2), encoding="utf-8")


def write_pack(paths: list[Path]) -> None:
    md = """# 男生展示面AI套图上架包

## 标题

男生展示面AI套图｜旅行/球场/商务三场景

## 核心定位

卖的是能发朋友圈、做头像、做展示面的男生内容，而不是单纯证件照。

## 价格

- 9.9 元：单图测试 + 风格建议
- 29 元：4图套装（旅行/球场/商务/头像）
- 99 元：12张展示面包 + 裁切建议

## 买家需要提供

清晰正脸照、想要的场景、风格参考、输出尺寸、是否要头像裁切。

## 边界

只接本人或授权照片；不接未授权明星照；不承诺平台过审和效果完全一致。

## 上架图

"""
    md += "\n".join(f"- {p}" for p in paths)
    md += "\n\n## 类目建议\n\n优先试 `AI图文工具/服务`，字段按 `计价方式=元/次`、`输入类型=文生图+图生图`、`功能类型=图片制作+图片修改`。\n"
    (OUT_DIR / "male_presence_publish_pack.md").write_text(md, encoding="utf-8")


def write_research_note() -> None:
    RESEARCH_DIR.mkdir(parents=True, exist_ok=True)
    note = """# 男生展示面需求依据

- Round 4 站内验证: `AI生成帅照` 有 131/74/57 人想要，`AI男生帅照` 和 `男士专属证件照` 也有对应需求。
- 这条更适合用“展示面套图”而不是单纯证件照，能覆盖朋友圈、头像、简历、社交展示。
- 复利资产: 男生展示面模板、球场抓拍模板、旅行模板、商务头像模板、裁切规范。
"""
    (RESEARCH_DIR / "positioning.md").write_text(note, encoding="utf-8")


def build_images() -> list[Path]:
    return [cover(), travel(), basketball(), business(), packages(), boundary()]


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
