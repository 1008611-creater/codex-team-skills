from __future__ import annotations

import argparse
import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(r"D:\codex-work\xianyu")
OUT_DIR = ROOT / "output" / "personal_memory_agent_pack"
PROMPT_DIR = ROOT / "prompts" / "personal_memory_agent"
RAW_DIR = OUT_DIR / "runninghub_raw"
IMG_DIR = OUT_DIR / "images_image2"
RESEARCH_DIR = OUT_DIR / "research"

W = H = 1242
FONT_REG = r"C:\Windows\Fonts\msyh.ttc"
FONT_BOLD = r"C:\Windows\Fonts\msyhbd.ttc"

PROMPTS = {
    "01_cover": """Create a premium square commercial poster background for a personal memory AI assistant / skill deployment service.

Visual concept:
- a private digital memory archive, clean timeline cards, encrypted document folders, a phone chat interface with abstract bubbles
- warm, quiet, respectful feeling, not romantic manipulation
- central laptop shows a generic AI assistant setup workflow and personal notes dashboard

Art direction:
- premium privacy-first software service, clean UI mockups, subtle cinematic lighting
- color palette: warm ivory, graphite, muted blue, soft amber
- strong blank space in upper-left and lower-right for Chinese overlay

Strict requirements:
- no readable text, no logos, no watermark
- no real chat content, no private names, no identifiable people, no celebrities
- output as polished 1:1 poster, ultra sharp""",
    "02_materials": """Create a square infographic background for organizing personal memory materials into an AI assistant.

Composition:
- left: abstract document cards, exported chat file icons, diary notes, photo placeholders
- center: privacy cleaning and structure pipeline
- right: clean knowledge base cards and assistant profile card

Style:
- privacy-first document workflow, warm and calm, professional
- white, graphite, muted blue, amber accents
- leave clean space for Chinese overlay

Strict requirements:
- no readable text, no logos, no watermark
- no actual chat screenshots, no identifiable people""",
    "03_deployment": """Create a premium technical service poster background for remote deployment of a personal AI assistant skill.

Composition:
- layers for environment check, open-source skill setup, knowledge folder, mobile access, testing
- include laptop, phone, secure folder, checklist cards, connection lines
- make it look like a real remote setup process

Style:
- enterprise software implementation infographic, soft and trustworthy
- clean dark panels on warm neutral background, blue and amber accents

Strict requirements:
- no readable text, no logos, no watermark
- no private data visible""",
    "04_mobile": """Create a square background showing a private personal memory AI assistant running on a phone.

Composition:
- phone mockup with abstract chat bubbles, memory timeline cards behind it, privacy lock icon, soft desk scene
- include backup/export file icons and small testing checklist cards

Style:
- calm premium SaaS lifestyle visual, not emotional exploitation
- warm ivory, muted blue, graphite, amber glow

Strict requirements:
- no readable text, no logos, no watermark
- no real chat content, no identifiable face or person""",
    "05_packages": """Create a premium three-tier service menu background for a personal memory AI assistant deployment service.

Composition:
- three vertical cards on a refined software-service background
- tiers visually imply: material assessment, basic deployment, memory archive plus mobile chat setup
- abstract icons for file, privacy shield, skill setup, phone chat, deletion checklist
- clear price spaces for later Chinese overlay

Style:
- clean service menu, high trust, privacy-first
- ivory, charcoal, muted blue, amber accents

Strict requirements:
- no readable text, no logos, no watermark""",
    "06_boundary": """Create a clean privacy and boundary checklist poster background for a personal memory AI assistant service.

Composition:
- two-column board: buyer provides and service delivers
- icons for authorized materials, device environment, mobile access, privacy, delete after delivery, guardrails
- bottom guardrail band with shield and lock icon

Style:
- minimal privacy-service infographic, white background, charcoal placeholder blocks, blue and amber accents
- calm, serious, trustworthy

Strict requirements:
- no readable text, no logos, no watermark
- no identifiable people, no private chats""",
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
    img, draw = layer("01_cover", darken=0.16)
    box(draw, (58, 64, 970, 590), fill=(9, 14, 22, 228), radius=42, outline=(82, 146, 220, 150))
    pill(draw, (96, 104), "前任Skill / 个人回忆 / 远程部署", (82, 146, 220, 246), size=27)
    draw.text((94, 178), "个人回忆AI助手", font=font(72, True), fill=(255, 255, 255))
    draw.text((98, 272), "聊天记录整理", font=font(56, True), fill=(255, 255, 255))
    draw.text((98, 346), "Skill部署跑通", font=font(56, True), fill=(244, 176, 83))
    draw.text((100, 450), "本人授权资料 / 手机对话入口 / 隐私删除说明", font=font(29), fill=(226, 236, 239))

    box(draw, (74, 906, 1168, 1162), fill=(255, 255, 255, 238), radius=36)
    draw.text((116, 944), "19.9 起", font=font(72, True), fill=(20, 24, 32))
    draw.text((420, 966), "评估 / 部署 / 资料整理", font=font(34, True), fill=(20, 24, 32))
    draw.text((118, 1054), "只做个人资料复盘助手，不做骚扰和冒充", font=font(30), fill=(82, 92, 108))
    return save(img, "01_Image2首图_个人回忆AI助手.png")


def materials() -> Path:
    img, draw = layer("02_materials", darken=0.03)
    box(draw, (58, 54, 1188, 224), fill=(255, 255, 255, 232), radius=30)
    draw.text((92, 82), "先整理资料，再部署助手", font=font(52, True), fill=(18, 24, 32))
    draw.text((94, 154), "聊天记录、日记、照片说明都要先清洗结构化", font=font(31), fill=(82, 92, 108))

    items = [("资料", "本人有权"), ("清洗", "去隐私"), ("结构", "时间线"), ("助手", "可对话")]
    for i, (title, sub) in enumerate(items):
        x = 84 + i * 288
        y = 888
        box(draw, (x, y, x + 246, y + 158), fill=(255, 255, 255, 236), radius=28)
        draw.text((x + 24, y + 26), title, font=font(34, True), fill=(18, 24, 32))
        draw.text((x + 24, y + 86), sub, font=font(24), fill=(82, 92, 108))

    box(draw, (84, 1072, 1166, 1164), fill=(9, 14, 22, 232), radius=28)
    draw.text((124, 1096), "不是复合承诺，是把回忆资料整理成个人助手", font=font(30, True), fill=(255, 255, 255))
    return save(img, "02_Image2_资料整理.png")


def deployment() -> Path:
    img, draw = layer("03_deployment", darken=0.04)
    box(draw, (58, 54, 1188, 224), fill=(255, 255, 255, 232), radius=30)
    draw.text((92, 82), "远程部署跑通", font=font(52, True), fill=(18, 24, 32))
    draw.text((94, 154), "环境检查、Skill安装、手机访问、测试说明", font=font(31), fill=(82, 146, 220))

    steps = [("01", "环境评估"), ("02", "Skill安装"), ("03", "资料导入"), ("04", "手机入口"), ("05", "删除说明")]
    for i, (num, label) in enumerate(steps):
        x = 84 + i * 220
        y = 878
        box(draw, (x, y, x + 184, y + 150), fill=(255, 255, 255, 236), radius=24)
        draw.text((x + 22, y + 20), num, font=font(28, True), fill=(18, 24, 32))
        draw.text((x + 22, y + 76), label, font=font(25, True), fill=(18, 24, 32))

    box(draw, (84, 1072, 1166, 1164), fill=(9, 14, 22, 232), radius=28)
    draw.text((124, 1096), "API Key 和账号由你本人输入，我不代管密钥", font=font(30, True), fill=(255, 255, 255))
    return save(img, "03_Image2_远程部署.png")


def mobile() -> Path:
    img, draw = layer("04_mobile", darken=0.03)
    box(draw, (58, 54, 1188, 224), fill=(255, 255, 255, 232), radius=30)
    draw.text((92, 82), "可做手机对话入口", font=font(52, True), fill=(18, 24, 32))
    draw.text((94, 154), "按你的环境评估，不承诺所有设备都能一次跑通", font=font(31), fill=(82, 92, 108))

    items = [("入口", "手机访问"), ("资料", "本地/云端"), ("测试", "问答验收"), ("交付", "说明文档")]
    for i, (title, sub) in enumerate(items):
        x = 84 + i * 288
        y = 888
        box(draw, (x, y, x + 246, y + 158), fill=(255, 255, 255, 236), radius=28)
        draw.text((x + 24, y + 26), title, font=font(34, True), fill=(18, 24, 32))
        draw.text((x + 24, y + 86), sub, font=font(24), fill=(82, 92, 108))

    box(draw, (84, 1072, 1166, 1164), fill=(9, 14, 22, 232), radius=28)
    draw.text((124, 1096), "更适合资料复盘、情绪记录、个人知识整理", font=font(30, True), fill=(255, 255, 255))
    return save(img, "04_Image2_手机入口.png")


def packages() -> Path:
    img, draw = layer("05_packages", darken=0.03)
    box(draw, (58, 54, 1188, 214), fill=(255, 255, 255, 232), radius=30)
    draw.text((92, 82), "套餐价格", font=font(54, True), fill=(18, 24, 32))
    draw.text((92, 152), "先评估，再决定是否部署", font=font(31), fill=(82, 92, 108))

    data = [
        ("19.9", "材料评估", ["资料类型", "设备环境", "风险边界"], (82, 146, 220)),
        ("99", "基础部署", ["Skill安装", "入口跑通", "测试说明"], (244, 176, 83)),
        ("299", "整理+部署", ["资料结构", "手机对话", "删除说明"], (71, 190, 92)),
    ]
    for i, (price, title, rows, color) in enumerate(data):
        x = 78 + i * 386
        box(draw, (x, 320, x + 344, 952), fill=(255, 255, 255, 238), radius=32, outline=color + (180,))
        draw.text((x + 34, 366), price, font=font(66, True), fill=(18, 24, 32))
        draw.text((x + 34, 472), title, font=font(38, True), fill=color)
        multiline(draw, (x + 36, 566), ["· " + row for row in rows], size=28, fill=(82, 92, 108), gap=26)

    box(draw, (84, 1032, 1166, 1148), fill=(9, 14, 22, 232), radius=28)
    draw.text((124, 1062), "主推 99：基础部署跑通，复杂资料另评估", font=font(30, True), fill=(255, 255, 255))
    return save(img, "05_Image2_套餐价格.png")


def boundary() -> Path:
    img, draw = layer("06_boundary", darken=0.02)
    box(draw, (58, 54, 1188, 214), fill=(255, 255, 255, 232), radius=30)
    draw.text((92, 82), "隐私边界写在前面", font=font(54, True), fill=(18, 24, 32))
    draw.text((92, 152), "只处理你本人有权使用的资料", font=font(31), fill=(224, 84, 58))

    box(draw, (88, 300, 590, 768), fill=(255, 255, 255, 234), radius=30)
    draw.text((126, 338), "你提供", font=font(38, True), fill=(18, 24, 32))
    multiline(draw, (130, 418), ["1. 本人授权资料", "2. 设备环境", "3. 是否手机访问", "4. 边界偏好"], size=28)

    box(draw, (650, 300, 1154, 768), fill=(255, 255, 255, 234), radius=30)
    draw.text((688, 338), "我交付", font=font(38, True), fill=(18, 24, 32))
    multiline(draw, (692, 418), ["1. 环境评估", "2. Skill部署", "3. 测试说明", "4. 删除说明"], size=28)

    box(draw, (88, 836, 1154, 1148), fill=(9, 14, 22, 234), radius=34)
    draw.text((126, 876), "不做这些", font=font(40, True), fill=(255, 255, 255))
    multiline(
        draw,
        (130, 952),
        ["不做骚扰、冒充他人、控制他人", "不做隐私窃取，不代管账号和密钥", "不承诺情感结果，只做资料助手"],
        size=28,
        fill=(220, 234, 238),
        gap=18,
    )
    return save(img, "06_Image2_隐私边界.png")


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
    title = "个人回忆AI助手｜前任Skill远程部署跑通"
    body = """如果你搜的是“前任Skill/个人回忆AI”，我这边只按安全版本来做：把你本人有权使用的聊天记录、日记、照片说明等资料，整理成个人回忆/资料复盘助手，并协助部署跑通。

可做：
1. 材料评估：看聊天记录、文档、图片说明是否适合整理
2. 资料结构：按时间线、人物关系、事件、关键词做整理建议
3. Skill部署：协助开源Skill/个人助手环境安装和配置
4. 手机入口：根据你的环境评估是否能手机访问
5. 隐私说明：交付后如何备份、删除、避免泄露

套餐：
19.9 元：材料评估 + 风险边界说明
99 元：基础部署 + 入口跑通 + 测试说明
299 元：资料整理建议 + 部署跑通 + 手机对话入口评估

下单前请先私聊发：
你想整理的资料类型、设备环境、是否需要手机访问、能接受的边界、是否已有API/模型。

说明：
只处理你本人有权使用的资料。
不做骚扰、冒充他人、控制他人、隐私窃取。
不代管账号、API Key、聊天记录原件；不承诺复合、挽回或任何情感结果。"""
    config = {
        "title": title,
        "body": body,
        "price": "19.90",
        "originalPrice": "299",
        "noShipping": True,
        "imagePaths": [str(p) for p in paths],
    }
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    (OUT_DIR / "publish_config_personal_memory_agent.json").write_text(json.dumps(config, ensure_ascii=False, indent=2), encoding="utf-8")
    (ROOT / "publish_config_personal_memory_agent.json").write_text(json.dumps(config, ensure_ascii=False, indent=2), encoding="utf-8")


def write_pack(paths: list[Path]) -> None:
    md = """# 个人回忆AI助手 / 前任Skill 上架包

## 标题

个人回忆AI助手｜前任Skill远程部署跑通

## 核心定位

吃“前任Skill”搜索，但交付必须安全改写为个人回忆资料整理和本人授权助手部署，不做骚扰、冒充、隐私窃取或情感承诺。

## 价格

- 19.9 元：材料评估 + 风险边界说明
- 99 元：基础部署 + 入口跑通 + 测试说明
- 299 元：资料整理建议 + 部署跑通 + 手机对话入口评估

## 买家需要提供

资料类型、设备环境、是否需要手机访问、边界偏好、是否已有API/模型。

## 边界

只处理买家本人有权使用的资料；不做骚扰、冒充他人、控制他人、隐私窃取；不代管账号/API Key；不承诺情感结果。

## 上架图

"""
    md += "\n".join(f"- {p}" for p in paths)
    md += "\n\n## 类目建议\n\n优先试 `AI提效工具`；若网页端自动分类到不支持类目，APP端或相邻AI服务类目兜底。\n"
    (OUT_DIR / "personal_memory_agent_publish_pack.md").write_text(md, encoding="utf-8")


def write_research_note() -> None:
    RESEARCH_DIR.mkdir(parents=True, exist_ok=True)
    note = """# 个人回忆AI助手 / 前任Skill需求依据

- Round 4 站内验证: `前任Skill 部署` 下 377 人想要，同词还有 81/58/25 人想要，价格带常见 18-52 元。
- 产品化判断: 需求真实，但必须改写成“个人回忆资料整理与本人授权部署”，不做骚扰、冒充、控制或隐私窃取。
- 复利资产: 部署SOP、隐私边界话术、聊天记录清洗模板、售前问答。
"""
    (RESEARCH_DIR / "positioning.md").write_text(note, encoding="utf-8")


def build_images() -> list[Path]:
    return [cover(), materials(), deployment(), mobile(), packages(), boundary()]


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
