from __future__ import annotations

import argparse
import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(r"D:\codex-work\xianyu")
OUT_DIR = ROOT / "output" / "korean_baseball_aiphoto_pack"
PROMPT_DIR = ROOT / "prompts" / "korean_baseball_aiphoto"
RAW_DIR = OUT_DIR / "runninghub_raw"
IMG_DIR = OUT_DIR / "images_image2"
RESEARCH_DIR = OUT_DIR / "research"

W = H = 1242
FONT_REG = r"C:\Windows\Fonts\msyh.ttc"
FONT_BOLD = r"C:\Windows\Fonts\msyhbd.ttc"

PROMPTS = {
    "01_cover": """Create a premium square commercial poster background for a Korean-style baseball spectator AI photo service.

Visual concept:
- a stylish synthetic young adult in a baseball stadium crowd, captured like a live broadcast camera suddenly found them
- include abstract phone preview cards, stadium lights, cheering crowd bokeh, score-screen shapes, and photo set thumbnails
- the feeling is realistic social-media display photo, not sports poster

Art direction:
- inspired by premium GPT Image 2 photography, lifestyle ad, and infographic cases
- high-end social portrait service, cinematic but believable, clean layout
- color palette: stadium navy, cream white, warm red, electric blue highlights
- strong blank space in upper-left and lower-right for Chinese overlay

Strict requirements:
- no readable text, no logos, no watermark
- no real teams, no real player, no public figure, no identifiable real person
- output as polished 1:1 poster, ultra sharp""",
    "02_single": """Create a square Korean-style baseball spectator photo workflow background.

Composition:
- left: generic face-reference card and style notes
- center: camera capture workflow and stadium scene cards
- right: realistic single-person spectator photo inside a packed baseball stadium
- make it feel like a candid broadcast shot, not a posed studio portrait

Style:
- premium lifestyle portrait board, clean and believable
- stadium navy, cream, red accent, cinematic lighting
- leave clear space for Chinese overlay

Strict requirements:
- no readable text, no logos, no watermark
- no public figures, no identifiable real person""",
    "03_couple": """Create a square Korean-style baseball game couple photo service background.

Composition:
- a stylish synthetic couple in a baseball stadium crowd, captured like a lively social-media moment
- include small live-photo frame strips, phone preview, cheering props, and scene variations
- romantic but natural, not overly posed

Style:
- premium lifestyle photography board, warm stadium lighting, clean UI cards
- leave blank space for Chinese overlay

Strict requirements:
- no readable text, no logos, no watermark
- no real teams, no public figures, no identifiable real people""",
    "04_video_live": """Create a square infographic background for turning baseball spectator AI photos into short video or Live photo style output.

Composition:
- show a row of frames: photo, subtle movement, camera zoom, cheering moment, final phone preview
- include generic video timeline, motion arrows, and output preview cards
- stadium background with lights and crowd blur

Style:
- premium AI video/photo service board, modern and clean
- navy, cream, red, electric blue accents

Strict requirements:
- no readable text, no logos, no watermark
- no identifiable face, no public figure""",
    "05_packages": """Create a premium three-tier service menu background for Korean-style baseball spectator AI photos.

Composition:
- three vertical service cards on a refined stadium/lifestyle background
- tiers visually imply: single test photo, four-photo set, photo plus short video/live photo
- include abstract icons for face reference, stadium scene, photo set, short video
- clear price spaces for later Chinese overlay

Style:
- clean social-photo service menu, energetic but premium
- stadium navy, white cards, red and blue accents

Strict requirements:
- no readable text, no logos, no watermark""",
    "06_boundary": """Create a clean material and boundary checklist poster background for an AI baseball spectator photo service.

Composition:
- two-column board: buyer provides and service delivers
- icons for own face photo, single/couple choice, outfit/style, stadium scene, photo set, privacy shield
- bottom guardrail band with shield icon

Style:
- minimal service infographic, white background, charcoal placeholder blocks, red and blue accents
- polished and trustworthy

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


def fit_square(path: Path, darken: float = 0.0) -> Image.Image:
    im = Image.open(path).convert("RGB")
    scale = max(W / im.width, H / im.height)
    im = im.resize((int(im.width * scale), int(im.height * scale)), Image.Resampling.LANCZOS)
    left = (im.width - W) // 2
    top = (im.height - H) // 2
    im = im.crop((left, top, left + W, top + H))
    if darken:
        im = Image.blend(im, Image.new("RGB", (W, H), (0, 0, 0)), darken)
    return im


def layer(name: str, darken: float = 0.0):
    img = fit_square(raw_for(name), darken=darken).convert("RGBA")
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
    img, draw = layer("01_cover", darken=0.20)
    box(draw, (58, 64, 956, 588), fill=(7, 12, 22, 228), radius=42, outline=(61, 150, 255, 150))
    pill(draw, (96, 104), "韩系棒球 / 直播镜头 / 朋友圈", (224, 58, 55, 246), size=27)
    draw.text((94, 178), "韩系棒球观众AI图", font=font(70, True), fill=(255, 255, 255))
    draw.text((98, 272), "直播镜头", font=font(58, True), fill=(255, 255, 255))
    draw.text((98, 348), "抓拍感", font=font(58, True), fill=(61, 180, 255))
    draw.text((100, 452), "单人 / 情侣 / 大屏 / 可做视频Live图", font=font(30), fill=(226, 236, 239))

    box(draw, (74, 906, 1168, 1162), fill=(255, 255, 255, 238), radius=36)
    draw.text((116, 944), "5 元起", font=font(72, True), fill=(20, 24, 32))
    draw.text((390, 966), "单张测试 / 4张套图 / 视频", font=font(34, True), fill=(20, 24, 32))
    draw.text((118, 1054), "适合朋友圈、小红书、头像、情侣整活", font=font(30), fill=(82, 92, 108))
    return save(img, "01_Image2首图_韩系棒球观众AI图.png")


def single() -> Path:
    img, draw = layer("02_single", darken=0.03)
    box(draw, (58, 54, 1188, 224), fill=(255, 255, 255, 232), radius=30)
    draw.text((92, 82), "像被镜头扫到", font=font(52, True), fill=(18, 24, 32))
    draw.text((94, 154), "不是影楼照，是球场观众抓拍感", font=font(31), fill=(82, 92, 108))

    items = [("照片", "清晰正脸"), ("风格", "韩系球场"), ("镜头", "直播抓拍"), ("输出", "社媒发图")]
    for i, (title, sub) in enumerate(items):
        x = 84 + i * 288
        y = 888
        box(draw, (x, y, x + 246, y + 158), fill=(255, 255, 255, 236), radius=28)
        draw.text((x + 24, y + 26), title, font=font(34, True), fill=(18, 24, 32))
        draw.text((x + 24, y + 86), sub, font=font(24), fill=(82, 92, 108))

    box(draw, (84, 1072, 1166, 1164), fill=(7, 12, 22, 232), radius=28)
    draw.text((124, 1096), "重点是自然、现场感、能发朋友圈", font=font(30, True), fill=(255, 255, 255))
    return save(img, "02_Image2_单人抓拍.png")


def couple() -> Path:
    img, draw = layer("03_couple", darken=0.04)
    box(draw, (58, 54, 1188, 224), fill=(255, 255, 255, 232), radius=30)
    draw.text((92, 82), "情侣也能做", font=font(52, True), fill=(18, 24, 32))
    draw.text((94, 154), "单人、情侣、朋友同框都可以先评估", font=font(31), fill=(224, 58, 55))

    items = [("人数", "单人/双人"), ("服装", "球衣/日常"), ("表情", "自然互动"), ("输出", "套图/视频")]
    for i, (title, sub) in enumerate(items):
        x = 84 + i * 288
        y = 888
        box(draw, (x, y, x + 246, y + 158), fill=(255, 255, 255, 236), radius=28)
        draw.text((x + 24, y + 26), title, font=font(34, True), fill=(18, 24, 32))
        draw.text((x + 24, y + 86), sub, font=font(24), fill=(82, 92, 108))

    box(draw, (84, 1072, 1166, 1164), fill=(7, 12, 22, 232), radius=28)
    draw.text((124, 1096), "情侣整活建议先做静态图，再加视频", font=font(30, True), fill=(255, 255, 255))
    return save(img, "03_Image2_情侣同框.png")


def video_live() -> Path:
    img, draw = layer("04_video_live", darken=0.04)
    box(draw, (58, 54, 1188, 224), fill=(255, 255, 255, 232), radius=30)
    draw.text((92, 82), "可加做视频 / Live图", font=font(52, True), fill=(18, 24, 32))
    draw.text((94, 154), "用静态图做轻微运镜和现场氛围", font=font(31), fill=(61, 150, 255))

    steps = [("01", "先出图"), ("02", "选中图"), ("03", "加运镜"), ("04", "导短片"), ("05", "发社媒")]
    for i, (num, label) in enumerate(steps):
        x = 84 + i * 220
        y = 878
        box(draw, (x, y, x + 184, y + 150), fill=(255, 255, 255, 236), radius=24)
        draw.text((x + 22, y + 20), num, font=font(28, True), fill=(18, 24, 32))
        draw.text((x + 22, y + 76), label, font=font(26, True), fill=(18, 24, 32))

    box(draw, (84, 1072, 1166, 1164), fill=(7, 12, 22, 232), radius=28)
    draw.text((124, 1096), "视频建议 3-5 秒，适合朋友圈 Live 图效果", font=font(30, True), fill=(255, 255, 255))
    return save(img, "04_Image2_视频Live图.png")


def packages() -> Path:
    img, draw = layer("05_packages", darken=0.03)
    box(draw, (58, 54, 1188, 214), fill=(255, 255, 255, 232), radius=30)
    draw.text((92, 82), "套餐价格", font=font(54, True), fill=(18, 24, 32))
    draw.text((92, 152), "低价测试，视频加价", font=font(31), fill=(82, 92, 108))

    data = [
        ("5", "单张测试", ["1张出图", "风格建议", "可轻微重出"], (224, 58, 55)),
        ("19", "4张套图", ["单人/情侣", "多角度", "社媒发图"], (61, 150, 255)),
        ("49", "图+视频", ["4张图", "3-5秒视频", "Live图感"], (245, 134, 38)),
    ]
    for i, (price, title, rows, color) in enumerate(data):
        x = 78 + i * 386
        box(draw, (x, 320, x + 344, 952), fill=(255, 255, 255, 238), radius=32, outline=color + (180,))
        draw.text((x + 34, 366), price, font=font(76, True), fill=(18, 24, 32))
        draw.text((x + 34, 472), title, font=font(38, True), fill=color)
        multiline(draw, (x + 36, 566), ["· " + row for row in rows], size=28, fill=(82, 92, 108), gap=26)

    box(draw, (84, 1032, 1166, 1148), fill=(7, 12, 22, 232), radius=28)
    draw.text((124, 1062), "主推 19：4张球场套图，更容易发朋友圈", font=font(30, True), fill=(255, 255, 255))
    return save(img, "05_Image2_套餐价格.png")


def boundary() -> Path:
    img, draw = layer("06_boundary", darken=0.02)
    box(draw, (58, 54, 1188, 214), fill=(255, 255, 255, 232), radius=30)
    draw.text((92, 82), "下单前先看", font=font(54, True), fill=(18, 24, 32))
    draw.text((92, 152), "只接本人或授权照片，不做明星脸", font=font(31), fill=(224, 58, 55))

    box(draw, (88, 300, 590, 768), fill=(255, 255, 255, 234), radius=30)
    draw.text((126, 338), "你提供", font=font(38, True), fill=(18, 24, 32))
    multiline(draw, (130, 418), ["1. 清晰正脸照", "2. 单人/情侣", "3. 球衣/表情要求", "4. 是否要视频"], size=28)

    box(draw, (650, 300, 1154, 768), fill=(255, 255, 255, 234), radius=30)
    draw.text((688, 338), "我交付", font=font(38, True), fill=(18, 24, 32))
    multiline(draw, (692, 418), ["1. 棒球观众图", "2. 大屏抓拍感", "3. 套图建议", "4. 可选短视频"], size=28)

    box(draw, (88, 836, 1154, 1148), fill=(7, 12, 22, 234), radius=34)
    draw.text((126, 876), "说明", font=font(40, True), fill=(255, 255, 255))
    multiline(
        draw,
        (130, 952),
        ["AI相似度会有波动，不保证完全像本人", "不接未授权明星照、公众人物照", "视频效果需先看静态图是否适配"],
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
    title = "韩系棒球观众AI图｜直播镜头抓拍感可做视频"
    body = """最近很火的韩系棒球观众照，核心不是“换个背景”，而是像被直播镜头扫到、能直接发朋友圈/小红书的抓拍感。

我这边做的是 韩系棒球观众AI图 / 视频Live图：适合单人、情侣、朋友同框、头像、朋友圈整活。

可做：
1. 单人球场观众图：像被镜头扫到的自然抓拍感
2. 情侣/朋友同框：先评估素材，再做同框图
3. 大屏/直播框风格：更像现场被拍到
4. 4张套图：适合发朋友圈和小红书
5. 可加做 3-5 秒短视频 / Live图感效果

套餐：
5 元：单张测试
19 元：4张球场套图
49 元：4张图 + 3-5 秒短视频/Live图感

下单前请先私聊发：
清晰正脸照、单人/双人、想要球衣还是日常穿搭、表情要求、是否要视频。

说明：
只接本人或授权照片。
不接未授权明星照、公众人物照。
AI相似度会有波动，不保证完全像本人；视频效果需要先看静态图是否适配。"""
    config = {
        "title": title,
        "body": body,
        "price": "5.00",
        "originalPrice": "49",
        "noShipping": True,
        "imagePaths": [str(p) for p in paths],
    }
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    (OUT_DIR / "publish_config_korean_baseball_aiphoto.json").write_text(json.dumps(config, ensure_ascii=False, indent=2), encoding="utf-8")
    (ROOT / "publish_config_korean_baseball_aiphoto.json").write_text(json.dumps(config, ensure_ascii=False, indent=2), encoding="utf-8")


def write_pack(paths: list[Path]) -> None:
    md = """# 韩系棒球观众AI图上架包

## 标题

韩系棒球观众AI图｜直播镜头抓拍感可做视频

## 核心定位

卖的是“像被球场直播镜头扫到”的社交展示图，不是普通背景替换。

## 价格

- 5 元：单张测试
- 19 元：4张球场套图
- 49 元：4张图 + 3-5 秒短视频/Live图感

## 买家需要提供

清晰正脸照、单人/双人、想要球衣还是日常穿搭、表情要求、是否要视频。

## 边界

只接本人或授权照片；不接未授权明星照、公众人物照；AI相似度会有波动，不保证完全像本人。

## 上架图

"""
    md += "\n".join(f"- {p}" for p in paths)
    md += "\n\n## 类目建议\n\n优先试 `AI图文工具/服务`；如主打视频加价，可以试 `AI视频工具/服务`。\n"
    (OUT_DIR / "korean_baseball_aiphoto_publish_pack.md").write_text(md, encoding="utf-8")


def write_research_note() -> None:
    RESEARCH_DIR.mkdir(parents=True, exist_ok=True)
    note = """# 韩系棒球观众AI图需求依据

- Round 4 站内验证: `韩系棒球观众AI图` 最高 200 人想要，同词还有 133/57/28 人想要，静态图常见 5 元，视频 15 元起。
- 外部热点: Jina 读取 Threads 2026-05-07 韩国球场 AI照片讨论，捕获 33.2K views。
- 产品化判断: 这条适合做低价流量入口，用 5 元单张测试引流，向 19 元套图和 49 元视频/Live图升级。
- 复利资产: Image2提示词、球场抓拍模板、视频模板、朋友圈文案模板，可导流到男生展示面和AI形象照。
"""
    (RESEARCH_DIR / "positioning.md").write_text(note, encoding="utf-8")


def build_images() -> list[Path]:
    return [cover(), single(), couple(), video_live(), packages(), boundary()]


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
