from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont


ROOT = Path(r"D:\codex-work\xianyu")
OUT_DIR = ROOT / "output" / "openclaw_skill_custom_pack"
PROMPT_DIR = ROOT / "prompts" / "openclaw_skill_custom"
RAW_DIR = OUT_DIR / "runninghub_raw"
IMG_DIR = OUT_DIR / "images_image2"
RESEARCH_DIR = OUT_DIR / "research"

W = H = 1242
FONT_REG = r"C:\Windows\Fonts\msyh.ttc"
FONT_BOLD = r"C:\Windows\Fonts\msyhbd.ttc"

FALLBACK_RAW = {
    "01_cover": ROOT / "output" / "openclaw_listing_pack" / "runninghub_raw" / "541b80dd-5fc2-4c6e-bde8-cdcd7ba0a650.png",
    "02_sop_to_skill": ROOT / "output" / "openclaw_listing_pack" / "runninghub_raw" / "30154d19-bdd8-408d-b2c8-9676d9a1f798.png",
    "03_skill_library": ROOT / "output" / "openclaw_listing_pack" / "runninghub_raw" / "0016bec2-dbb4-4e4c-b846-76372b935e38.png",
    "04_scenarios": ROOT / "output" / "openclaw_listing_pack" / "runninghub_raw" / "e321db88-8a15-4f59-aad8-ee95b6b79ece.png",
    "05_packages": ROOT / "output" / "openclaw_listing_pack" / "runninghub_raw" / "b4da9603-8235-4d87-a2c3-549e12800aa8.png",
    "06_boundary": ROOT / "output" / "openclaw_listing_pack" / "runninghub_raw" / "990e5c80-d97e-49cd-b914-882c326b77cc.png",
}

PROMPTS = {
    "01_cover": """Create a premium square poster for an OpenClaw AI Agent Skill customization service.

Style:
- sophisticated AI systems poster
- dark glassmorphism workstation, glowing modular cards, teal and amber accents
- business automation, not a cartoon animal theme
- high-end SaaS product launch visual

Composition:
- central laptop showing a generic agent workflow canvas
- floating cards representing SOP, Skill.md, testing, deployment
- elegant negative space at top left and bottom right for later Chinese overlay

Requirements:
- no readable text
- no brand logos
- no watermarks
- no mascot, no literal lobster""",
    "02_sop_to_skill": """Create a clean technical infographic poster showing an SOP converted into an AI Agent skill.

Composition:
- left side: paper documents, checklist cards, messy process notes
- center: a refined transformation pipeline with arrows
- right side: a clean modular Skill.md file card and testing console
- make it feel like professional workflow engineering

Style:
- museum catalog infographic meets enterprise AI product diagram
- white and charcoal background, teal and copper highlights
- crisp lines, precise spacing, premium finish

Requirements:
- no readable text
- no logos
- leave blank areas for Chinese labels""",
    "03_skill_library": """Create a premium catalog board for an OpenClaw skill library.

Composition:
- many modular cards arranged in a clean grid
- categories suggested visually: office automation, research notes, content creation, ecommerce operations, code assistant, data cleanup
- one highlighted custom skill card in the center

Style:
- Swiss modernist catalog design
- subtle ivory background, dark ink, teal accents
- high trust, highly organized, not cluttered

Requirements:
- no readable words
- no logos
- no watermark""",
    "04_scenarios": """Create a four-quadrant AI automation scenarios poster.

Quadrants:
- office workflow
- content creation
- ecommerce operations
- research and learning

Visuals:
- each quadrant shows a polished desk scene with relevant generic icons and workflow cards
- all scenes connected by a subtle agent network line

Style:
- premium product strategy board
- clean, realistic, editorial, modern
- leave label space for later Chinese overlay

Requirements:
- no readable text
- no logos
- no watermark""",
    "05_packages": """Create a premium three-tier service package poster for AI agent skill customization.

Composition:
- three vertical service cards on an elegant background
- tiers visually imply: diagnosis, skill draft, custom implementation
- each card includes abstract icon, checklist shapes, and refined price space

Style:
- high-end service menu, Swiss design, restrained luxury
- ivory, charcoal, teal, copper
- precise grid, strong hierarchy

Requirements:
- no readable text
- no logos
- leave top area for headline and price overlays""",
    "06_boundary": """Create a clean trust and safety checklist poster for an AI agent customization service.

Composition:
- two columns: buyer provides / service delivers
- include abstract icons for document, laptop, key, shield, test result, deployment
- bottom area has a clear warning/guardrail band

Style:
- professional software service infographic
- clean white background, dark text placeholders, teal and amber accents
- polished and calm

Requirements:
- no readable text
- no logos
- no watermark""",
}


def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(FONT_BOLD if bold else FONT_REG, size=size)


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


def raw_for(name: str) -> Path:
    folder = RAW_DIR / name
    if folder.exists():
        images = sorted(
            [p for p in folder.iterdir() if p.suffix.lower() in {".png", ".jpg", ".jpeg", ".webp"}],
            key=lambda p: p.stat().st_mtime,
        )
        if images:
            return images[-1]
    return FALLBACK_RAW[name]


def layer(name: str, darken: float = 0.0, blur: float = 0.0):
    img = fit_square(raw_for(name), darken=darken, blur=blur).convert("RGBA")
    return img, ImageDraw.Draw(img)


def save(img: Image.Image, name: str) -> Path:
    IMG_DIR.mkdir(parents=True, exist_ok=True)
    path = IMG_DIR / name
    img.convert("RGB").save(path, quality=95)
    return path


def box(draw: ImageDraw.ImageDraw, xy, fill=(255, 255, 255, 226), radius=32, outline=None):
    draw.rounded_rectangle(xy, radius=radius, fill=fill, outline=outline, width=2 if outline else 1)


def pill(draw: ImageDraw.ImageDraw, xy, text: str, fill, fg=(255, 255, 255), size=28):
    x, y = xy
    f = font(size, True)
    b = draw.textbbox((0, 0), text, font=f)
    tw, th = b[2] - b[0], b[3] - b[1]
    draw.rounded_rectangle((x, y, x + tw + 44, y + th + 28), radius=999, fill=fill)
    draw.text((x + 22, y + 12), text, font=f, fill=fg)


def multiline(draw: ImageDraw.ImageDraw, xy, lines, size=28, fill=(80, 90, 106), gap=12, bold=False):
    x, y = xy
    f = font(size, bold)
    for line in lines:
        draw.text((x, y), line, font=f, fill=fill)
        h = draw.textbbox((x, y), line, font=f)[3] - y
        y += h + gap
    return y


def write_prompts() -> None:
    PROMPT_DIR.mkdir(parents=True, exist_ok=True)
    for name, prompt in PROMPTS.items():
        (PROMPT_DIR / f"{name}.txt").write_text(prompt.strip() + "\n", encoding="utf-8")


def cover() -> Path:
    img, draw = layer("01_cover", darken=0.18)
    box(draw, (58, 66, 820, 548), fill=(8, 16, 22, 222), radius=42, outline=(56, 220, 180, 150))
    pill(draw, (94, 104), "OpenClaw / 龙虾 Skill", (15, 156, 144, 245), size=28)
    draw.text((94, 176), "Skill 定制", font=font(82, True), fill=(255, 255, 255))
    draw.text((96, 274), "把 SOP 变成技能", font=font(54, True), fill=(255, 255, 255))
    draw.text((98, 356), "让龙虾真正按你的流程干活", font=font(34), fill=(214, 232, 229))
    draw.text((98, 410), "不是乱装插件，而是做可复用工作流", font=font(30), fill=(214, 232, 229))

    box(draw, (74, 908, 1168, 1164), fill=(255, 255, 255, 236), radius=36)
    draw.text((116, 944), "9.9 起", font=font(72, True), fill=(20, 24, 32))
    draw.text((374, 964), "诊断 / 草稿 / 定制 Skill", font=font(36, True), fill=(20, 24, 32))
    draw.text((118, 1054), "适合办公、电商、内容创作、资料整理、研究笔记", font=font(30), fill=(82, 92, 108))
    return save(img, "01_Image2首图_OpenClaw_Skill定制.png")


def sop_to_skill() -> Path:
    img, draw = layer("02_sop_to_skill", darken=0.04)
    box(draw, (58, 54, 1188, 226), fill=(255, 255, 255, 226), radius=30)
    draw.text((92, 82), "你给流程，我写成 Skill.md", font=font(50, True), fill=(18, 24, 32))
    draw.text((94, 154), "把重复工作拆成步骤、输入、检查点和输出", font=font(31), fill=(82, 92, 108))

    items = [("01", "拆任务"), ("02", "写规则"), ("03", "加工具"), ("04", "跑测试")]
    for i, (num, label) in enumerate(items):
        x = 94 + i * 280
        y = 892
        box(draw, (x, y, x + 232, y + 154), fill=(255, 255, 255, 232), radius=28)
        draw.text((x + 24, y + 22), num, font=font(30, True), fill=(18, 24, 32))
        draw.text((x + 24, y + 76), label, font=font(33, True), fill=(18, 24, 32))

    box(draw, (84, 1074, 1166, 1164), fill=(13, 22, 28, 230), radius=28)
    draw.text((124, 1098), "交付不是一句提示词，而是一套可复用的执行说明", font=font(30, True), fill=(255, 255, 255))
    return save(img, "02_Image2_SOP变Skill.png")


def skill_library() -> Path:
    img, draw = layer("03_skill_library", darken=0.06)
    box(draw, (58, 54, 1188, 226), fill=(255, 255, 255, 226), radius=30)
    draw.text((92, 82), "Skill 不是越多越好", font=font(52, True), fill=(18, 24, 32))
    draw.text((94, 154), "要按你的业务目标组合，减少冲突和无效折腾", font=font(31), fill=(82, 92, 108))

    tags = ["搜索资料", "整理文档", "闲鱼上架", "视频脚本", "电商作图", "客户回复", "日报周报", "代码辅助", "知识库", "自动复盘"]
    x0, y0 = 84, 842
    for i, tag in enumerate(tags):
        x = x0 + (i % 5) * 218
        y = y0 + (i // 5) * 92
        box(draw, (x, y, x + 194, y + 62), fill=(255, 255, 255, 232), radius=18)
        draw.text((x + 20, y + 16), tag, font=font(24, True), fill=(23, 31, 40))

    box(draw, (82, 1064, 1160, 1152), fill=(13, 22, 28, 230), radius=28)
    draw.text((124, 1086), "先做场景诊断，再决定装什么、写什么、测试什么", font=font(30, True), fill=(255, 255, 255))
    return save(img, "03_Image2_Skill组合库.png")


def scenarios() -> Path:
    img, draw = layer("04_scenarios", darken=0.02)
    box(draw, (58, 54, 1188, 226), fill=(255, 255, 255, 226), radius=30)
    draw.text((92, 82), "四类高频场景", font=font(54, True), fill=(18, 24, 32))
    draw.text((94, 154), "把你已经在做的流程沉淀成长期资产", font=font(31), fill=(15, 143, 142))

    cards = [
        ((92, 312), "闲鱼上架", ["需求挖掘", "文案重构", "配图发布"]),
        ((650, 312), "内容创作", ["选题拆解", "脚本初稿", "封面文案"]),
        ((92, 720), "电商运营", ["商品图", "详情页", "带货视频"]),
        ((650, 720), "知识整理", ["网页读取", "资料摘要", "FAQ沉淀"]),
    ]
    for (x, y), title, rows in cards:
        box(draw, (x, y, x + 492, y + 184), fill=(255, 255, 255, 230), radius=28)
        draw.text((x + 30, y + 28), title, font=font(36, True), fill=(18, 24, 32))
        multiline(draw, (x + 32, y + 92), [" / ".join(rows)], size=25, fill=(82, 92, 108))

    box(draw, (82, 1050, 1160, 1150), fill=(255, 255, 255, 234), radius=28)
    draw.text((124, 1078), "定制一个 Skill，就是多一个可复用的员工动作", font=font(31, True), fill=(18, 24, 32))
    return save(img, "04_Image2_适用场景.png")


def packages() -> Path:
    img, draw = layer("05_packages", darken=0.04)
    box(draw, (58, 54, 1188, 214), fill=(255, 255, 255, 226), radius=30)
    draw.text((92, 82), "套餐价格", font=font(54, True), fill=(18, 24, 32))
    draw.text((92, 152), "从低价诊断，到真正定制一个 Skill", font=font(31), fill=(82, 92, 108))

    data = [
        ("9.9", "清单避坑", ["必装Skill建议", "安装前准备", "适合先了解"], (15, 143, 142)),
        ("59", "SOP诊断", ["流程拆解", "Skill结构草稿", "输入输出建议"], (43, 106, 220)),
        ("399", "定制Skill", ["写Skill.md", "跑一轮测试", "交付说明"], (242, 132, 41)),
    ]
    for i, (price, title, rows, color) in enumerate(data):
        x = 78 + i * 386
        box(draw, (x, 320, x + 344, 952), fill=(255, 255, 255, 236), radius=32, outline=color + (180,))
        draw.text((x + 34, 366), price, font=font(76, True), fill=(18, 24, 32))
        draw.text((x + 34, 470), title, font=font(36, True), fill=color)
        multiline(draw, (x + 36, 562), ["· " + row for row in rows], size=28, fill=(82, 92, 108), gap=24)

    box(draw, (84, 1032, 1166, 1148), fill=(13, 22, 28, 230), radius=28)
    draw.text((124, 1062), "主推 399：把你的真实工作流程写成一个可测试 Skill", font=font(30, True), fill=(255, 255, 255))
    return save(img, "05_Image2_套餐价格.png")


def boundary() -> Path:
    img, draw = layer("06_boundary", darken=0.02)
    box(draw, (58, 54, 1188, 214), fill=(255, 255, 255, 226), radius=30)
    draw.text((92, 82), "下单前发这些", font=font(54, True), fill=(18, 24, 32))
    draw.text((92, 152), "资料越清楚，Skill 越容易一次成型", font=font(31), fill=(242, 132, 41))

    box(draw, (88, 300, 590, 760), fill=(255, 255, 255, 232), radius=30)
    draw.text((126, 338), "你提供", font=font(38, True), fill=(18, 24, 32))
    multiline(draw, (130, 418), ["1. 想自动化的工作", "2. 现有SOP/文档", "3. 常用网站或工具", "4. 期望输出格式"], size=28)

    box(draw, (650, 300, 1154, 760), fill=(255, 255, 255, 232), radius=30)
    draw.text((688, 338), "我交付", font=font(38, True), fill=(18, 24, 32))
    multiline(draw, (692, 418), ["1. Skill.md结构", "2. 使用说明", "3. 测试清单", "4. 常见报错建议"], size=28)

    box(draw, (88, 836, 1154, 1148), fill=(13, 22, 28, 232), radius=34)
    draw.text((126, 876), "边界说明", font=font(40, True), fill=(255, 255, 255))
    multiline(
        draw,
        (130, 952),
        ["不做批量骚扰 / 风控绕过 / 隐私窃取", "API Key 由买家本人输入，不代管密钥", "复杂系统先评估，再确认能不能做"],
        size=28,
        fill=(220, 234, 238),
        gap=18,
    )
    return save(img, "06_Image2_发图要求与边界.png")


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
    title = "OpenClaw龙虾Skill定制｜把你的SOP变成技能"
    body = """最近 OpenClaw/龙虾很火，但很多人卡住的不是聊天，而是：不知道怎么让它按自己的业务流程稳定干活。

我这边做的是 OpenClaw 龙虾 Skill 定制/梳理，把你的 SOP、重复工作、资料处理流程，整理成更容易复用的 Skill.md 和测试说明。

可做：
1. 需求拆解：把你想自动化的工作拆成输入、步骤、检查点、输出
2. Skill 草稿：把现有 SOP 改写成 OpenClaw/Agent 能读懂的 Skill.md
3. 场景定制：闲鱼上架、资料整理、短剧脚本、电商作图、客户回复、研究笔记等
4. Skill 组合建议：不是乱装几千个，而是按你的目标选必装组合
5. 测试与排错：给你一套怎么跑、怎么验收、常见问题怎么改的说明

套餐：
9.9 元：必装 Skill 清单 + 避坑说明
59 元：一份 SOP 诊断 + Skill 结构草稿
399 元：推荐套餐，定制 1 个 Skill.md + 使用说明 + 一轮测试建议

下单前请先私聊发：
你想自动化的工作、现有 SOP/文档/截图、常用网站或工具、期望输出格式、是否已经在用 OpenClaw/Claude Code/Codex。

说明：
不做批量骚扰、绕过平台风控、账号劫持、隐私窃取等用途。
API Key 和账号授权由你本人输入，我不代管密钥。
复杂系统需要先评估，不承诺一次写完就适配所有环境。"""
    config = {
        "title": title,
        "body": body,
        "price": "9.90",
        "originalPrice": "399",
        "noShipping": True,
        "imagePaths": [str(p) for p in paths],
    }
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    (OUT_DIR / "publish_config_openclaw_skill_custom.json").write_text(json.dumps(config, ensure_ascii=False, indent=2), encoding="utf-8")
    (ROOT / "publish_config_openclaw_skill_custom.json").write_text(json.dumps(config, ensure_ascii=False, indent=2), encoding="utf-8")


def write_pack(paths: list[Path]) -> None:
    md = """# OpenClaw 龙虾 Skill 定制上架包

## 标题

OpenClaw龙虾Skill定制｜把你的SOP变成技能

## 核心定位

和已发布的“OpenClaw龙虾部署”区分开：这个商品卖的是把用户已有流程改造成可复用 Skill，不是单纯安装。

## 价格

- 9.9 元：必装 Skill 清单 + 避坑说明
- 59 元：一份 SOP 诊断 + Skill 结构草稿
- 399 元：定制 1 个 Skill.md + 使用说明 + 一轮测试建议

## 上架图

"""
    md += "\n".join(f"- {p}" for p in paths)
    md += "\n\n## 类目建议\n\nAI提效工具；如果网页端不支持，优先尝试 AI图文工具/服务 或 APP 端。\n"
    (OUT_DIR / "openclaw_skill_custom_publish_pack.md").write_text(md, encoding="utf-8")


def write_research_note() -> None:
    RESEARCH_DIR.mkdir(parents=True, exist_ok=True)
    note = """# OpenClaw Skill 定制需求依据

- Round 4 站内验证: OpenClaw 技能关键词下，18123个技能库商品 159 人想要，5000+技能商品 128 人想要，咨询服务 94 人想要，定制技能包 49 人想要。
- 外部热度: Jina 读取 YouTube OpenClaw/龙虾讲解，捕获 935,515 views、21K likes、560 comments。
- 产品化判断: 旧商品已经覆盖“部署/必装Skills配置”，新商品要上升到“把SOP变成Skill”，客单价和复利都更高。
- 图像策略: 复用前一轮 RunningHub Image2 原创无字底图，但重新叠字和重构信息架构，避免与已发布商品同款。
"""
    (RESEARCH_DIR / "positioning.md").write_text(note, encoding="utf-8")


def main() -> None:
    write_prompts()
    missing = [str(path) for path in FALLBACK_RAW.values() if not path.exists()]
    if missing:
        raise FileNotFoundError("\n".join(missing))
    paths = [cover(), sop_to_skill(), skill_library(), scenarios(), packages(), boundary()]
    contact_sheet(paths)
    write_config(paths)
    write_pack(paths)
    write_research_note()
    print(json.dumps({"outDir": str(OUT_DIR), "images": [str(p) for p in paths], "contactSheet": str(IMG_DIR / "image2_contact_sheet.png")}, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
