from __future__ import annotations

import argparse
import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont


ROOT = Path(r"D:\codex-work\xianyu")
OUT_DIR = ROOT / "output" / "short_drama_agent_pack"
PROMPT_DIR = ROOT / "prompts" / "short_drama_agent"
RAW_DIR = OUT_DIR / "runninghub_raw"
IMG_DIR = OUT_DIR / "images_image2"
RESEARCH_DIR = OUT_DIR / "research"

W = H = 1242
FONT_REG = r"C:\Windows\Fonts\msyh.ttc"
FONT_BOLD = r"C:\Windows\Fonts\msyhbd.ttc"

PROMPTS = {
    "01_cover": """Create a premium square commercial poster background for an AI short-drama script generation Agent / web tool.

Visual concept:
- a cinematic writer's command center for short drama production
- central laptop/browser interface showing abstract episode cards, plot arcs, character cards, and a timeline
- a stack of generic novel pages transforming into structured episode boards
- energetic but premium, not cheap, not cartoonish

Art direction:
- inspired by high-value GPT Image 2 UI/interface and infographic cases
- editorial SaaS launch visual, clean grid, realistic UI mockup, subtle cinematic lighting
- color palette: deep ink, warm cream, electric cyan, punchy red accent
- strong blank space in upper-left and lower-right for later Chinese overlay

Strict requirements:
- no readable text, no real brand logos, no watermark
- no celebrity, no copyrighted character
- output as polished 1:1 poster, ultra sharp""",
    "02_novel_to_episode": """Create a premium 1:1 infographic background showing the process of turning a novel excerpt into a short-drama episode outline.

Composition:
- left: messy manuscript pages and highlighted story fragments
- center: an elegant transformation pipeline with arrows and small abstract icons
- right: clean structured episode table cards, scene beats, hook markers, character motivation chips
- make it look like a professional AI writing workflow board

Style:
- Swiss modernist information design mixed with cinematic screenwriting studio
- white and charcoal surfaces, warm paper texture, cyan and red accents
- leave clear empty bands for Chinese overlay

Strict requirements:
- no readable text, no logos, no watermark
- no plagiarism references, no known IP""",
    "03_batch_outline": """Create a high-end UI dashboard background for a short-drama outline generator.

Composition:
- large web app dashboard with a grid of many episode cards
- each card has abstract thumbnails, beat dots, hook indicators, tension curve mini charts
- side panel suggests genre presets: romance, revenge, workplace, fantasy, family ethics, but do not use readable words
- include one highlighted output preview card

Style:
- premium product UI mockup, crisp glass panels, dark mode with warm paper cards
- sophisticated creator tool, not generic AI poster
- cinematic but clean, high trust, high productivity

Strict requirements:
- no readable text, no logos, no watermark
- leave top area and bottom area uncluttered for Chinese overlay""",
    "04_packages": """Create a premium three-tier service package poster background for an AI short-drama script Agent service.

Composition:
- three vertical cards on a clean editorial background
- tiers visually imply: prompt template pack, 10-episode structure diagnosis, custom Agent/workflow
- include abstract icons for prompt, diagnosis, web agent, script table
- strong hierarchy and blank spaces for later Chinese price labels

Style:
- Swiss design service menu, premium SaaS pricing page, clean shadows
- warm ivory, deep charcoal, cyan, red-orange accents
- very polished, print-ready

Strict requirements:
- no readable text, no logos, no watermark""",
    "05_audience": """Create a four-quadrant visual board background for short-drama creators.

Quadrants:
- short-drama account operator
- novel adaptation planner
- comic / storyboard creator
- content matrix team

Composition:
- each quadrant shows a realistic desk/workspace scene with abstract script cards, timeline boards, phone preview panels, and analytics shapes
- connect quadrants with subtle AI workflow lines

Style:
- premium editorial infographic, modern Chinese creator economy aesthetic
- bright but controlled palette, not childish
- leave label space in each quadrant

Strict requirements:
- no readable text, no logos, no watermark
- no public figures""",
    "06_boundary": """Create a clean service checklist poster background for an AI script generation service.

Composition:
- two-column checklist board: buyer materials and service delivery
- abstract icons for authorized material, topic, episode count, platform, output format, revision
- bottom guardrail band with shield and document icon
- professional service terms visual

Style:
- minimal software service infographic, white background, charcoal placeholder blocks, cyan and warm red accents
- calm, trustworthy, precise

Strict requirements:
- no readable text, no logos, no watermark
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
    box(draw, (58, 64, 936, 574), fill=(10, 14, 22, 226), radius=42, outline=(23, 214, 220, 160))
    pill(draw, (96, 104), "短剧号 / 小说改编 / 矩阵内容", (224, 55, 54, 246), size=27)
    draw.text((94, 176), "AI短剧剧本生成", font=font(72, True), fill=(255, 255, 255))
    draw.text((98, 270), "小说改短剧", font=font(58, True), fill=(255, 255, 255))
    draw.text((98, 344), "分集大纲 Agent", font=font(58, True), fill=(28, 230, 228))
    draw.text((100, 440), "题材 / 人设 / 爽点 / 反转 / 分集节奏", font=font(31), fill=(226, 236, 239))

    box(draw, (74, 906, 1168, 1162), fill=(255, 255, 255, 238), radius=36)
    draw.text((116, 944), "9.9 起", font=font(72, True), fill=(20, 24, 32))
    draw.text((372, 966), "模板包 / 结构诊断 / 定制Agent", font=font(34, True), fill=(20, 24, 32))
    draw.text((118, 1054), "不卖玄学爆款，交付可复用的剧本生产流程", font=font(30), fill=(82, 92, 108))
    return save(img, "01_Image2首图_AI短剧剧本生成.png")


def novel_to_episode() -> Path:
    img, draw = layer("02_novel_to_episode", darken=0.04)
    box(draw, (58, 54, 1188, 224), fill=(255, 255, 255, 232), radius=30)
    draw.text((92, 82), "从小说片段到分集表", font=font(52, True), fill=(18, 24, 32))
    draw.text((94, 154), "先拆爽点，再排节奏，不是一键乱写", font=font(31), fill=(82, 92, 108))

    items = [("题材", "甜宠/逆袭/悬疑"), ("人设", "欲望与冲突"), ("钩子", "前三秒爆点"), ("分集", "每集推进")]
    for i, (title, sub) in enumerate(items):
        x = 84 + i * 288
        y = 888
        box(draw, (x, y, x + 246, y + 158), fill=(255, 255, 255, 236), radius=28)
        draw.text((x + 24, y + 26), title, font=font(34, True), fill=(18, 24, 32))
        draw.text((x + 24, y + 86), sub, font=font(24), fill=(82, 92, 108))

    box(draw, (84, 1072, 1166, 1164), fill=(10, 14, 22, 232), radius=28)
    draw.text((124, 1096), "适合做短剧号选题、小说改编、漫剧脚本初稿", font=font(30, True), fill=(255, 255, 255))
    return save(img, "02_Image2_小说到分集表.png")


def batch_outline() -> Path:
    img, draw = layer("03_batch_outline", darken=0.12)
    box(draw, (58, 54, 1188, 226), fill=(12, 18, 28, 226), radius=30, outline=(28, 230, 228, 130))
    draw.text((92, 82), "批量产出，不等于粗糙复制", font=font(50, True), fill=(255, 255, 255))
    draw.text((94, 154), "模板化的是结构，差异化的是题材和卖点", font=font(31), fill=(216, 232, 237))

    tags = ["人物小传", "主线冲突", "分集钩子", "反转节点", "高能对白", "结尾悬念"]
    for i, tag in enumerate(tags):
        x = 92 + (i % 3) * 360
        y = 858 + (i // 3) * 96
        box(draw, (x, y, x + 312, y + 66), fill=(255, 255, 255, 234), radius=18)
        draw.text((x + 24, y + 17), tag, font=font(27, True), fill=(18, 24, 32))

    box(draw, (84, 1066, 1162, 1154), fill=(224, 55, 54, 238), radius=28)
    draw.text((124, 1088), "可交付：大纲模板 + 提示词 + 可选网页Agent入口", font=font(30, True), fill=(255, 255, 255))
    return save(img, "03_Image2_批量大纲Agent.png")


def packages() -> Path:
    img, draw = layer("04_packages", darken=0.03)
    box(draw, (58, 54, 1188, 214), fill=(255, 255, 255, 232), radius=30)
    draw.text((92, 82), "三档交付", font=font(54, True), fill=(18, 24, 32))
    draw.text((92, 152), "低价入门，高价做定制流程", font=font(31), fill=(82, 92, 108))

    data = [
        ("9.9", "模板包", ["短剧提示词", "人设表", "分集表"], (224, 55, 54)),
        ("39", "结构诊断", ["10集结构", "爽点检查", "节奏建议"], (22, 150, 178)),
        ("199", "定制Agent", ["赛道模板", "网页入口", "SOP说明"], (245, 134, 38)),
    ]
    for i, (price, title, rows, color) in enumerate(data):
        x = 78 + i * 386
        box(draw, (x, 320, x + 344, 952), fill=(255, 255, 255, 238), radius=32, outline=color + (180,))
        draw.text((x + 34, 366), price, font=font(78, True), fill=(18, 24, 32))
        draw.text((x + 34, 472), title, font=font(38, True), fill=color)
        multiline(draw, (x + 36, 566), ["· " + row for row in rows], size=28, fill=(82, 92, 108), gap=26)

    box(draw, (84, 1032, 1166, 1148), fill=(10, 14, 22, 232), radius=28)
    draw.text((124, 1062), "主推 199：按你的赛道做一套可复用剧本生成工作流", font=font(30, True), fill=(255, 255, 255))
    return save(img, "04_Image2_套餐价格.png")


def audience() -> Path:
    img, draw = layer("05_audience", darken=0.04)
    box(draw, (58, 54, 1188, 224), fill=(255, 255, 255, 232), radius=30)
    draw.text((92, 82), "适合这些买家", font=font(54, True), fill=(18, 24, 32))
    draw.text((94, 154), "不是作家专用，是内容矩阵的生产工具", font=font(31), fill=(22, 150, 178))

    cards = [
        ((92, 314), "短剧号", ["选题", "分集", "标题"]),
        ((650, 314), "小说改编", ["人设", "冲突", "爽点"]),
        ((92, 724), "漫剧分镜", ["对白", "画面", "节奏"]),
        ((650, 724), "矩阵团队", ["批量", "复盘", "迭代"]),
    ]
    for (x, y), title, rows in cards:
        box(draw, (x, y, x + 492, y + 184), fill=(255, 255, 255, 234), radius=28)
        draw.text((x + 30, y + 28), title, font=font(38, True), fill=(18, 24, 32))
        draw.text((x + 32, y + 98), " / ".join(rows), font=font(28), fill=(82, 92, 108))

    box(draw, (82, 1050, 1160, 1150), fill=(255, 255, 255, 236), radius=28)
    draw.text((124, 1078), "买家发题材和目标，我帮你搭一套能反复用的模板", font=font(31, True), fill=(18, 24, 32))
    return save(img, "05_Image2_适合人群.png")


def boundary() -> Path:
    img, draw = layer("06_boundary", darken=0.02)
    box(draw, (58, 54, 1188, 214), fill=(255, 255, 255, 232), radius=30)
    draw.text((92, 82), "下单前先看边界", font=font(54, True), fill=(18, 24, 32))
    draw.text((92, 152), "能提升效率，不承诺爆款和收益", font=font(31), fill=(224, 55, 54))

    box(draw, (88, 300, 590, 768), fill=(255, 255, 255, 234), radius=30)
    draw.text((126, 338), "你提供", font=font(38, True), fill=(18, 24, 32))
    multiline(draw, (130, 418), ["1. 题材/小说片段", "2. 目标平台", "3. 集数与时长", "4. 风格禁区"], size=28)

    box(draw, (650, 300, 1154, 768), fill=(255, 255, 255, 234), radius=30)
    draw.text((688, 338), "我交付", font=font(38, True), fill=(18, 24, 32))
    multiline(draw, (692, 418), ["1. 大纲模板", "2. 分集节奏", "3. 提示词SOP", "4. 可选Agent入口"], size=28)

    box(draw, (88, 836, 1154, 1148), fill=(10, 14, 22, 234), radius=34)
    draw.text((126, 876), "说明", font=font(40, True), fill=(255, 255, 255))
    multiline(
        draw,
        (130, 952),
        ["不承诺爆款、收益、平台过审", "不做未授权小说/影视IP改编", "买家需提供有权使用的素材"],
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
    title = "AI短剧剧本生成｜小说改短剧分集大纲Agent"
    body = """闲鱼上短剧剧本生成很热，但低价提示词很多问题是：能出字，不能稳定出结构。

我这边做的是 AI短剧剧本生成 Agent / 工作流：把你的题材、小说片段、目标平台和集数要求，整理成可反复用的短剧大纲、人物小传、分集节奏和爽点提示词。

可做：
1. 小说/题材拆解：拆主线、人设、冲突、爽点、反转
2. 分集大纲：按集数生成每集钩子、推进点、结尾悬念
3. 短剧提示词包：适合甜宠、逆袭、悬疑、职场、家庭伦理等方向
4. 结构诊断：帮你看10集结构哪里平、哪里缺冲突
5. 定制Agent/网页入口：按你的赛道做一套可复用剧本生成流程

套餐：
9.9 元：短剧提示词 + 分集表模板
39 元：10集短剧结构诊断 + 爽点建议
199 元：按你的赛道定制剧本Agent/工作流 + 使用说明

下单前请先私聊发：
题材/小说片段、目标平台、预计集数、单集时长、想要的风格、不能出现的内容、是否需要网页/Agent入口。

说明：
不承诺爆款、收益、平台过审。
不做未授权小说/影视IP改编，不接侵权搬运。
AI初稿需要人工筛选和二次打磨，适合提高效率，不替代最终编审。"""
    config = {
        "title": title,
        "body": body,
        "price": "9.90",
        "originalPrice": "199",
        "noShipping": True,
        "imagePaths": [str(p) for p in paths],
    }
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    (OUT_DIR / "publish_config_short_drama_agent.json").write_text(json.dumps(config, ensure_ascii=False, indent=2), encoding="utf-8")
    (ROOT / "publish_config_short_drama_agent.json").write_text(json.dumps(config, ensure_ascii=False, indent=2), encoding="utf-8")


def write_pack(paths: list[Path]) -> None:
    md = """# AI短剧剧本生成 Agent 上架包

## 标题

AI短剧剧本生成｜小说改短剧分集大纲Agent

## 核心定位

不做单纯“几条提示词合集”，而是卖可反复用的短剧生产流程：题材拆解、人物小传、分集表、爽点节奏、可选网页/Agent入口。

## 价格

- 9.9 元：短剧提示词 + 分集表模板
- 39 元：10集短剧结构诊断 + 爽点建议
- 199 元：按赛道定制剧本Agent/工作流 + 使用说明

## 买家需要提供

题材/小说片段、目标平台、预计集数、单集时长、风格禁区、是否需要网页/Agent入口。

## 边界

不承诺爆款、收益、平台过审；不做未授权小说/影视IP改编；AI初稿需要人工二次打磨。

## 上架图

"""
    md += "\n".join(f"- {p}" for p in paths)
    md += "\n\n## 类目建议\n\n优先试 `AI提效工具`；如果被拦截，再试 `AI图文工具/服务` 并填 `计价方式=元/次`。\n"
    (OUT_DIR / "short_drama_agent_publish_pack.md").write_text(md, encoding="utf-8")


def write_research_note() -> None:
    RESEARCH_DIR.mkdir(parents=True, exist_ok=True)
    note = """# AI短剧剧本生成需求依据

- Round 4 站内验证: `AI短剧剧本 生成` 下最高 1577 人想要，标题强调“一键生成500集短剧剧本，是网站不是软件”。
- 同词下还有 186 人想要的小说转短剧AI提示词，116/84 人想要的短剧剧本指令合集，说明网站入口、提示词包和流程诊断都能卖。
- 价格带低，但可以用 9.9 元承接搜索流量，把客单价抬到 39 元结构诊断和 199 元定制 Agent。
- 账号复利资产: 短剧提示词库、赛道模板、Agent站点、买家题材需求库、后续可拆分“分镜脚本 / 漫剧分镜图 / Nano Banana分镜工作流”。
- Image2参考: 参考 image2 案例库中的 UI界面、图表信息图、商业海报方向，底图重点做真实工具界面和流程板，中文卖点本地后期叠加。
"""
    (RESEARCH_DIR / "positioning.md").write_text(note, encoding="utf-8")


def build_images() -> list[Path]:
    return [cover(), novel_to_episode(), batch_outline(), packages(), audience(), boundary()]


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
