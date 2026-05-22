from __future__ import annotations

import argparse
import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont


ROOT = Path(r"D:\codex-work\xianyu")
OUT_DIR = ROOT / "output" / "ai_fashion_tryon_pack"
PROMPT_DIR = ROOT / "prompts" / "ai_fashion_tryon"
RAW_DIR = OUT_DIR / "runninghub_raw"
IMG_DIR = OUT_DIR / "images_image2"
RESEARCH_DIR = OUT_DIR / "research"

W = H = 1242
FONT_REG = r"C:\Windows\Fonts\msyh.ttc"
FONT_BOLD = r"C:\Windows\Fonts\msyhbd.ttc"

PROMPTS = {
    "01_cover": """Create a premium square commercial poster background for an AI fashion try-on / e-commerce model styling service.

Visual concept:
- a high-end fashion content workspace
- central monitor displays a before/after wardrobe transformation board, model cards, product photo cards, and scene shots
- elegant synthetic model silhouette in multiple outfit variations, all generic and non-identifiable
- the feeling should be editorial and commercial, not fake or playful

Art direction:
- inspired by premium GPT Image 2 ecommerce and infographic cases
- luxury fashion brand presentation, crisp UI mockup, polished studio lighting
- color palette: soft ivory, graphite, muted blush, black, gold accent
- strong blank space in upper-left and lower-right for Chinese overlay

Strict requirements:
- no readable text, no logos, no watermark
- no public figure, no celebrity, no identifiable real person
- output as polished 1:1 poster, ultra sharp""",
    "02_before_after": """Create a high-end square infographic background showing a clothing product photo transformed into a worn-on-model fashion scene.

Composition:
- left: garment/product photo card, flat lay or hanging item, generic and non-identifiable
- center: transformation pipeline and styling cards
- right: model wearing the outfit in a clean street/editorial scene
- include small frame strips and quality markers

Style:
- premium ecommerce infographic, editorial fashion board, clean studio composition
- white, cream, graphite, subtle blush accents
- leave clear empty space for later Chinese overlay

Strict requirements:
- no readable text, no logos, no watermark
- no identifiable person or public figure""",
    "03_use_cases": """Create a four-quadrant fashion AI service board background.

Quadrants:
- main image for clothing store
- model try-on scene
- social media outfit post
- cross-border e-commerce scene

Composition:
- each quadrant shows a polished generic model, outfit cards, and product composition panels
- connect quadrants with subtle workflow arrows
- make it look like a real commercial production tool

Style:
- premium editorial infographic, high trust, clean and modern
- balanced light background with dark UI blocks
- leave label space in each quadrant

Strict requirements:
- no readable text, no logos, no watermark
- no public figures""",
    "04_deployment": """Create a premium service poster background for an AI fashion try-on / outfit generation workflow.

Composition:
- visual steps for material check, body pose selection, scene matching, output preview, batch variation
- include fashion cards, product image cards, pose references, and output thumbnails
- make it feel like a real service workflow rather than a generic art poster

Style:
- enterprise fashion production infographic
- polished white studio background with gold and graphite accents
- precise spacing, high trust, commercial

Strict requirements:
- no readable text, no logos, no watermark
- no public figure imagery""",
    "05_packages": """Create a premium three-tier service menu background for an AI fashion try-on service.

Composition:
- three vertical cards on a refined fashion studio background
- tiers visually imply: single-image test, six-image set, workflow + SKU run-through
- include abstract icons for product photo, model photo, scene preview, batch set
- clear price spaces for later Chinese overlay

Style:
- luxury service menu, clean editorial layout, soft neutral palette, gold accent
- sharp and premium

Strict requirements:
- no readable text, no logos, no watermark""",
    "06_boundary": """Create a clean trust-and-boundary checklist poster background for an AI fashion try-on service.

Composition:
- two-column board: buyer provides and service delivers
- icons for garment photo, model reference, scene style, output size, revision, privacy shield
- bottom guardrail band with shield icon
- professional and calm

Style:
- minimal fashion-service infographic, white background, charcoal placeholder blocks, blush and gold accents
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
    box(draw, (58, 64, 954, 586), fill=(10, 12, 18, 228), radius=42, outline=(214, 177, 92, 150))
    pill(draw, (96, 104), "穿搭号 / 女装卖家 / 跨境电商", (214, 177, 92, 246), size=27)
    draw.text((94, 178), "AI活人感穿搭图文", font=font(70, True), fill=(255, 255, 255))
    draw.text((98, 272), "电商模特换装", font=font(56, True), fill=(255, 255, 255))
    draw.text((98, 346), "场景图", font=font(56, True), fill=(214, 177, 92))
    draw.text((100, 450), "商品图 / 模特图 / 场景图 / 批量套图", font=font(30), fill=(226, 236, 239))

    box(draw, (74, 906, 1168, 1162), fill=(255, 255, 255, 238), radius=36)
    draw.text((116, 944), "9.9 起", font=font(72, True), fill=(20, 24, 32))
    draw.text((372, 966), "测试 / 套图 / 批量工作流", font=font(34, True), fill=(20, 24, 32))
    draw.text((118, 1054), "适合服装卖家、穿搭号、独立站、跨境电商", font=font(30), fill=(82, 92, 108))
    return save(img, "01_Image2首图_AI活人感穿搭图文.png")


def before_after() -> Path:
    img, draw = layer("02_before_after", darken=0.03)
    box(draw, (58, 54, 1188, 224), fill=(255, 255, 255, 232), radius=30)
    draw.text((92, 82), "商品图到上身场景", font=font(52, True), fill=(18, 24, 32))
    draw.text((94, 154), "不是只换背景，而是做更像真人在穿的内容", font=font(31), fill=(82, 92, 108))

    items = [("商品", "平铺/挂拍"), ("模特", "姿态参考"), ("场景", "街拍/室内"), ("输出", "套图导出")]
    for i, (title, sub) in enumerate(items):
        x = 84 + i * 288
        y = 888
        box(draw, (x, y, x + 246, y + 158), fill=(255, 255, 255, 236), radius=28)
        draw.text((x + 24, y + 26), title, font=font(34, True), fill=(18, 24, 32))
        draw.text((x + 24, y + 86), sub, font=font(24), fill=(82, 92, 108))

    box(draw, (84, 1072, 1166, 1164), fill=(10, 12, 18, 232), radius=28)
    draw.text((124, 1096), "重点：上身感、面料感、场景感都要稳", font=font(30, True), fill=(255, 255, 255))
    return save(img, "02_Image2_商品到上身场景.png")


def use_cases() -> Path:
    img, draw = layer("03_use_cases", darken=0.08)
    box(draw, (58, 54, 1188, 224), fill=(10, 12, 18, 228), radius=30, outline=(214, 177, 92, 120))
    draw.text((92, 82), "四类最容易成交的场景", font=font(50, True), fill=(255, 255, 255))
    draw.text((94, 154), "卖家要的不是概念，是能直接发图的内容", font=font(31), fill=(220, 236, 238))

    cards = [
        ((92, 314), "服装卖家", ["主图", "详情页", "套图"]),
        ((650, 314), "穿搭账号", ["朋友圈", "小红书", "展示面"]),
        ((92, 724), "跨境独立站", ["白底图", "场景图", "变体"]),
        ((650, 724), "批量运营", ["SKU", "模板", "复用"]),
    ]
    for (x, y), title, rows in cards:
        box(draw, (x, y, x + 492, y + 184), fill=(255, 255, 255, 234), radius=28)
        draw.text((x + 30, y + 28), title, font=font(38, True), fill=(18, 24, 32))
        draw.text((x + 32, y + 98), " / ".join(rows), font=font(28), fill=(82, 92, 108))

    box(draw, (82, 1050, 1160, 1150), fill=(255, 255, 255, 236), radius=28)
    draw.text((124, 1078), "先做单图测试，再进到 6 张套图和批量流程", font=font(31, True), fill=(18, 24, 32))
    return save(img, "03_Image2_适用场景.png")


def deployment() -> Path:
    img, draw = layer("04_deployment", darken=0.04)
    box(draw, (58, 54, 1188, 224), fill=(255, 255, 255, 232), radius=30)
    draw.text((92, 82), "工作流不是只出图", font=font(54, True), fill=(18, 24, 32))
    draw.text((94, 154), "还要能稳定适配 SKU、尺码、风格和场景", font=font(31), fill=(214, 177, 92))

    steps = [("01", "商品检查"), ("02", "模特参考"), ("03", "场景匹配"), ("04", "输出预览"), ("05", "批量套图")]
    for i, (num, label) in enumerate(steps):
        x = 84 + i * 220
        y = 878
        box(draw, (x, y, x + 184, y + 150), fill=(255, 255, 255, 236), radius=24)
        draw.text((x + 22, y + 20), num, font=font(28, True), fill=(18, 24, 32))
        draw.text((x + 22, y + 76), label, font=font(26, True), fill=(18, 24, 32))

    box(draw, (84, 1072, 1166, 1164), fill=(10, 12, 18, 232), radius=28)
    draw.text((124, 1096), "可做单SKU，也可做店铺统一风格的批量模板", font=font(30, True), fill=(255, 255, 255))
    return save(img, "04_Image2_工作流跑通.png")


def packages() -> Path:
    img, draw = layer("05_packages", darken=0.03)
    box(draw, (58, 54, 1188, 214), fill=(255, 255, 255, 232), radius=30)
    draw.text((92, 82), "套餐价格", font=font(54, True), fill=(18, 24, 32))
    draw.text((92, 152), "低价测试到批量工作流", font=font(31), fill=(82, 92, 108))

    data = [
        ("9.9", "单图测试", ["1张效果图", "风格建议", "是否可做"], (214, 177, 92)),
        ("59", "6张套图", ["主图/详情", "穿搭场景", "批量输出"], (76, 154, 255)),
        ("199", "批量工作流", ["SKU模板", "统一风格", "复用说明"], (245, 134, 38)),
    ]
    for i, (price, title, rows, color) in enumerate(data):
        x = 78 + i * 386
        box(draw, (x, 320, x + 344, 952), fill=(255, 255, 255, 238), radius=32, outline=color + (180,))
        draw.text((x + 34, 366), price, font=font(76, True), fill=(18, 24, 32))
        draw.text((x + 34, 472), title, font=font(38, True), fill=color)
        multiline(draw, (x + 36, 566), ["· " + row for row in rows], size=28, fill=(82, 92, 108), gap=26)

    box(draw, (84, 1032, 1166, 1148), fill=(10, 12, 18, 232), radius=28)
    draw.text((124, 1062), "主推 199：从单张效果图到批量 SKU 模板", font=font(30, True), fill=(255, 255, 255))
    return save(img, "05_Image2_套餐价格.png")


def boundary() -> Path:
    img, draw = layer("06_boundary", darken=0.02)
    box(draw, (58, 54, 1188, 214), fill=(255, 255, 255, 232), radius=30)
    draw.text((92, 82), "边界先说清", font=font(54, True), fill=(18, 24, 32))
    draw.text((92, 152), "只接有权使用的商品图和模特参考", font=font(31), fill=(220, 134, 38))

    box(draw, (88, 300, 590, 768), fill=(255, 255, 255, 234), radius=30)
    draw.text((126, 338), "你提供", font=font(38, True), fill=(18, 24, 32))
    multiline(draw, (130, 418), ["1. 商品图/服装图", "2. 模特参考或风格", "3. 场景要求", "4. 输出尺寸"], size=28)

    box(draw, (650, 300, 1154, 768), fill=(255, 255, 255, 234), radius=30)
    draw.text((688, 338), "我交付", font=font(38, True), fill=(18, 24, 32))
    multiline(draw, (692, 418), ["1. 场景图", "2. 套图建议", "3. 批量思路", "4. 风格说明"], size=28)

    box(draw, (88, 836, 1154, 1148), fill=(10, 12, 18, 234), radius=34)
    draw.text((126, 876), "说明", font=font(40, True), fill=(255, 255, 255))
    multiline(
        draw,
        (130, 952),
        ["不接未授权人脸或明星照", "不承诺平台过审和销量", "复杂纹理和极端姿态需要先测试"],
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
    title = "AI活人感穿搭图文｜电商模特换装场景图"
    body = """现在很多服装卖家和穿搭号，卡的不是会不会发图，而是：没有真人感、没有场景感、没有持续出图的模板。

我这边做的是 AI活人感穿搭图文 / 电商模特换装场景图：把你的商品图、服装图、模特参考和风格要求，整理成更像真人上身、能直接发图的内容。

可做：
1. 商品图变上身场景：把平铺图、挂拍图、商品图做成更像真人在穿的图
2. 模特换装：按指定风格生成穿搭图、详情图、场景图
3. 社媒展示面：朋友圈、小红书、穿搭号、男/女装展示图
4. 跨境电商图：适合独立站、SKU变体、场景图批量化
5. 批量思路：给你单图测试、6张套图、批量工作流的说明

套餐：
9.9 元：单图测试 + 风格建议
59 元：6张套图（主图/详情/场景）
199 元：批量工作流 + SKU模板 + 复用说明

下单前请先私聊发：
商品图/服装图、模特参考或风格方向、场景要求、输出尺寸、是否要批量化。

说明：
只接有权使用的商品图和模特参考。
不接未授权人脸或明星照。
不承诺平台过审和销量，复杂纹理和极端姿态需要先测试。"""
    config = {
        "title": title,
        "body": body,
        "price": "9.90",
        "originalPrice": "199",
        "noShipping": True,
        "imagePaths": [str(p) for p in paths],
    }
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    (OUT_DIR / "publish_config_ai_fashion_tryon.json").write_text(json.dumps(config, ensure_ascii=False, indent=2), encoding="utf-8")
    (ROOT / "publish_config_ai_fashion_tryon.json").write_text(json.dumps(config, ensure_ascii=False, indent=2), encoding="utf-8")


def write_pack(paths: list[Path]) -> None:
    md = """# AI活人感穿搭图文上架包

## 标题

AI活人感穿搭图文｜电商模特换装场景图

## 核心定位

卖的是“更像真人在穿的服装图”和“能批量复用的穿搭场景模板”，不是简单换背景。

## 价格

- 9.9 元：单图测试 + 风格建议
- 59 元：6张套图（主图/详情/场景）
- 199 元：批量工作流 + SKU模板 + 复用说明

## 买家需要提供

商品图/服装图、模特参考或风格方向、场景要求、输出尺寸、是否要批量化。

## 边界

只接有权使用的商品图和模特参考；不接未授权人脸或明星照；不承诺平台过审和销量。

## 上架图

"""
    md += "\n".join(f"- {p}" for p in paths)
    md += "\n\n## 类目建议\n\n优先试 `AI图文工具/服务`，字段按 `计价方式=元/次`、`输入类型=文生图+图生图`、`功能类型=图片制作+图片修改`。\n"
    (OUT_DIR / "ai_fashion_tryon_publish_pack.md").write_text(md, encoding="utf-8")


def write_research_note() -> None:
    RESEARCH_DIR.mkdir(parents=True, exist_ok=True)
    note = """# AI活人感穿搭图文 / 电商模特换装需求依据

- Round 4 站内验证: `AI电商模特换装` 有 258/97/86 人想要的信号；`AI生成活人感穿搭图文` 方向也有直接想要数。
- 这个方向最适合承接服装卖家、穿搭号、跨境电商和朋友圈展示面需求。
- 产品化判断: 买家最在意的是是否能批量、是否能像真人、是否能复用成 SKU 模板。
- 复利资产: 商品图模板、穿搭场景模板、SKU 流程、批量输出规范、买家素材要求清单。
"""
    (RESEARCH_DIR / "positioning.md").write_text(note, encoding="utf-8")


def build_images() -> list[Path]:
    return [cover(), before_after(), use_cases(), deployment(), packages(), boundary()]


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
