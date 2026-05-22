from __future__ import annotations

import argparse
import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont


ROOT = Path(r"D:\codex-work\xianyu")
OUT_DIR = ROOT / "output" / "nano_banana_storyboard_pack"
PROMPT_DIR = ROOT / "prompts" / "nano_banana_storyboard"
RAW_DIR = OUT_DIR / "runninghub_raw"
IMG_DIR = OUT_DIR / "images_image2"
RESEARCH_DIR = OUT_DIR / "research"

W = H = 1242
FONT_REG = r"C:\Windows\Fonts\msyh.ttc"
FONT_BOLD = r"C:\Windows\Fonts\msyhbd.ttc"

PROMPTS = {
    "01_cover": """Create a premium square commercial poster background for an AI comic short-drama storyboard workflow service.

Visual concept:
- a cinematic creator command center for AI comic / mini-drama storyboarding
- central desktop monitor shows abstract 9-grid, 16-grid, and 25-grid storyboard boards
- character consistency cards, scene cards, camera angle chips, and a clean workflow timeline
- strong sense of "from script to visual storyboard", polished and commercially useful

Art direction:
- inspired by GPT Image 2 UI/interface cases, Swiss typography posters, and premium infographic cases
- high-end SaaS product launch visual, crisp UI mockup, cinematic lighting
- palette: deep ink, warm paper, electric cyan, vermilion red, small gold accent
- clear blank space in upper-left and lower-right for Chinese overlay

Strict requirements:
- no readable text, no logos, no watermark
- no celebrity, no copyrighted character, no real IP
- generic synthetic illustrated characters only
- output as polished 1:1 poster, ultra sharp""",
    "02_script_to_grid": """Create a premium square infographic background showing a script transforming into comic storyboard grids.

Composition:
- left side: abstract script pages and dialogue beat cards
- middle: elegant AI workflow pipeline with camera angle icons and scene planning chips
- right side: clean 9-grid and 16-grid storyboard thumbnails, with varied shots such as wide shot, medium shot, close-up, over-the-shoulder
- include a subtle "before to after" production-board feeling without readable text

Style:
- high-end creator tool infographic, Swiss grid, clean editorial layout
- warm paper, charcoal UI panels, cyan and red accents
- leave clean space for later Chinese labels

Strict requirements:
- no readable text, no brand logos, no watermark
- no known IP, no public figures""",
    "03_consistency": """Create a high-end AI character consistency board for comic / short-drama storyboards.

Composition:
- center: generic original character reference sheet, same character shown in front, side, expression, action pose
- surrounding panels: storyboard thumbnails keep the same character face, outfit, and scene style
- include visual locks, reference chips, and quality-check UI shapes but no readable text

Style:
- premium animation pre-production board, clean UI, cinematic but practical
- dark graphite background with warm paper cards, cyan highlight, red-orange key accent
- leave room for Chinese overlay at top and bottom

Strict requirements:
- no readable text, no logos, no watermark
- no celebrity, no copyrighted character, no identifiable real person""",
    "04_use_cases": """Create a four-quadrant visual board background for AI comic storyboard workflow use cases.

Quadrants:
- short-drama account storyboard
- novel-to-comic adaptation
- comic video / manhua reel production
- content matrix batch production

Composition:
- each quadrant shows a realistic creator workspace with abstract storyboard frames, phone preview panels, script cards, and production checklists
- connect quadrants with subtle workflow lines
- make it feel like a sellable practical service, not a generic AI artwork

Style:
- premium editorial infographic, modern Chinese creator economy aesthetic
- refined color contrast, clean UI panels, sharp details
- leave label space in each quadrant

Strict requirements:
- no readable text, no logos, no watermark
- no public figures or known IP""",
    "05_packages": """Create a premium three-tier service menu background for an AI comic storyboard workflow service.

Composition:
- three vertical pricing cards on a refined creator studio background
- tiers visually imply: prompt/template pack, workflow setup and debugging, custom storyboard system
- include abstract icons for prompt, grid storyboard, character consistency, workflow file, tutorial
- generous blank spaces for Chinese price labels

Style:
- Swiss design service menu, premium SaaS pricing page, clean shadows
- warm ivory, deep charcoal, cyan, vermilion red, gold accent

Strict requirements:
- no readable text, no logos, no watermark""",
    "06_boundary": """Create a clean service checklist poster background for an AI comic storyboard workflow service.

Composition:
- two-column checklist board: buyer provides and service delivers
- abstract icons for authorized script, character reference, scene style, grid size, output examples, revision
- bottom guardrail band with shield and copyright-safe document icon
- professional and trustworthy

Style:
- minimal software service infographic, white and charcoal background, cyan and warm red accents
- precise spacing, high trust, service-ready

Strict requirements:
- no readable text, no logos, no watermark
- no known IP, no public figures""",
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
    img, draw = layer("01_cover", darken=0.24)
    box(draw, (58, 64, 1002, 604), fill=(8, 12, 22, 230), radius=42, outline=(28, 230, 228, 150))
    pill(draw, (96, 104), "漫剧号 / 短剧号 / 小说推文", (224, 55, 54, 246), size=27)
    draw.text((94, 178), "AI漫剧分镜", font=font(76, True), fill=(255, 255, 255))
    draw.text((98, 278), "角色一致", font=font(58, True), fill=(255, 255, 255))
    draw.text((98, 354), "多宫格工作流", font=font(58, True), fill=(28, 230, 228))
    draw.text((100, 462), "9/16/25宫格 · 脚本转画面 · 可定制SOP", font=font(30), fill=(226, 236, 239))

    box(draw, (74, 906, 1168, 1162), fill=(255, 255, 255, 238), radius=36)
    draw.text((116, 944), "9.9 起", font=font(72, True), fill=(20, 24, 32))
    draw.text((372, 966), "提示词包 / 调试 / 定制分镜系统", font=font(34, True), fill=(20, 24, 32))
    draw.text((118, 1054), "不卖玄学教程，交付能复用的分镜生产流程", font=font(30), fill=(82, 92, 108))
    return save(img, "01_Image2首图_AI漫剧分镜工作流.png")


def script_to_grid() -> Path:
    img, draw = layer("02_script_to_grid", darken=0.04)
    box(draw, (58, 54, 1188, 224), fill=(255, 255, 255, 234), radius=30)
    draw.text((92, 82), "脚本变成分镜图", font=font(52, True), fill=(18, 24, 32))
    draw.text((94, 154), "先拆镜头，再生成宫格，不是随机出图", font=font(31), fill=(82, 92, 108))

    items = [("剧本", "对白/情绪"), ("镜头", "远中近特"), ("角色", "一致性"), ("输出", "9/16/25格")]
    for i, (title, sub) in enumerate(items):
        x = 84 + i * 288
        y = 888
        box(draw, (x, y, x + 246, y + 158), fill=(255, 255, 255, 236), radius=28)
        draw.text((x + 24, y + 26), title, font=font(34, True), fill=(18, 24, 32))
        draw.text((x + 24, y + 86), sub, font=font(24), fill=(82, 92, 108))

    box(draw, (84, 1072, 1166, 1164), fill=(8, 12, 22, 232), radius=28)
    draw.text((124, 1096), "适合小说推文、漫剧分镜、短剧前期视觉规划", font=font(30, True), fill=(255, 255, 255))
    return save(img, "02_Image2_脚本到分镜宫格.png")


def consistency() -> Path:
    img, draw = layer("03_consistency", darken=0.13)
    box(draw, (58, 54, 1188, 226), fill=(8, 12, 22, 228), radius=30, outline=(28, 230, 228, 130))
    draw.text((92, 82), "核心：人物和场景要稳", font=font(50, True), fill=(255, 255, 255))
    draw.text((94, 154), "同一个主角，跨镜头不跑脸、不跑衣服", font=font(31), fill=(216, 232, 237))

    tags = ["三视图", "表情组", "动作参考", "场景锁定", "镜头语言", "批量复用"]
    for i, tag in enumerate(tags):
        x = 92 + (i % 3) * 360
        y = 858 + (i // 3) * 96
        box(draw, (x, y, x + 312, y + 66), fill=(255, 255, 255, 234), radius=18)
        draw.text((x + 24, y + 17), tag, font=font(27, True), fill=(18, 24, 32))

    box(draw, (84, 1066, 1162, 1154), fill=(224, 55, 54, 238), radius=28)
    draw.text((124, 1088), "可交付：角色提示词 + 分镜模板 + 出图SOP", font=font(30, True), fill=(255, 255, 255))
    return save(img, "03_Image2_角色一致性分镜.png")


def use_cases() -> Path:
    img, draw = layer("04_use_cases", darken=0.06)
    box(draw, (58, 54, 1188, 224), fill=(255, 255, 255, 232), radius=30)
    draw.text((92, 82), "四类最容易成交的场景", font=font(50, True), fill=(18, 24, 32))
    draw.text((94, 154), "从教程资料，升级成能落地的生产流程", font=font(31), fill=(224, 55, 54))

    cards = [
        ((92, 314), "短剧号", ["分集", "镜头", "卡点"]),
        ((650, 314), "小说推文", ["人设", "场景", "情绪"]),
        ((92, 724), "漫剧视频", ["宫格", "对白", "运镜"]),
        ((650, 724), "矩阵团队", ["模板", "批量", "复盘"]),
    ]
    for (x, y), title, rows in cards:
        box(draw, (x, y, x + 492, y + 184), fill=(255, 255, 255, 234), radius=28)
        draw.text((x + 30, y + 28), title, font=font(38, True), fill=(18, 24, 32))
        draw.text((x + 32, y + 98), " / ".join(rows), font=font(28), fill=(82, 92, 108))

    box(draw, (82, 1050, 1160, 1150), fill=(8, 12, 22, 232), radius=28)
    draw.text((124, 1078), "买家发题材和角色，我帮你搭一套能反复用的分镜模板", font=font(30, True), fill=(255, 255, 255))
    return save(img, "04_Image2_适用场景.png")


def packages() -> Path:
    img, draw = layer("05_packages", darken=0.03)
    box(draw, (58, 54, 1188, 214), fill=(255, 255, 255, 232), radius=30)
    draw.text((92, 82), "三档交付", font=font(54, True), fill=(18, 24, 32))
    draw.text((92, 152), "低价验证，高价做定制流程", font=font(31), fill=(82, 92, 108))

    data = [
        ("9.9", "提示词包", ["宫格模板", "镜头词库", "角色规范"], (224, 55, 54)),
        ("59", "流程调试", ["选题拆镜", "样图反馈", "参数建议"], (22, 150, 178)),
        ("199", "定制系统", ["角色库", "分镜SOP", "可复用模板"], (245, 134, 38)),
    ]
    for i, (price, title, rows, color) in enumerate(data):
        x = 78 + i * 386
        box(draw, (x, 320, x + 344, 952), fill=(255, 255, 255, 238), radius=32, outline=color + (180,))
        draw.text((x + 34, 366), price, font=font(76, True), fill=(18, 24, 32))
        draw.text((x + 34, 472), title, font=font(38, True), fill=color)
        multiline(draw, (x + 36, 566), ["· " + row for row in rows], size=28, fill=(82, 92, 108), gap=26)

    box(draw, (84, 1032, 1166, 1148), fill=(8, 12, 22, 232), radius=28)
    draw.text((124, 1062), "主推 199：按你的题材做一套可复用分镜工作流", font=font(30, True), fill=(255, 255, 255))
    return save(img, "05_Image2_套餐价格.png")


def boundary() -> Path:
    img, draw = layer("06_boundary", darken=0.02)
    box(draw, (58, 54, 1188, 214), fill=(255, 255, 255, 232), radius=30)
    draw.text((92, 82), "下单前先看边界", font=font(54, True), fill=(18, 24, 32))
    draw.text((92, 152), "能提效，不承诺爆款、收益、过审", font=font(31), fill=(224, 55, 54))

    box(draw, (88, 300, 590, 768), fill=(255, 255, 255, 234), radius=30)
    draw.text((126, 338), "你提供", font=font(38, True), fill=(18, 24, 32))
    multiline(draw, (130, 418), ["1. 剧本/题材", "2. 角色设定", "3. 分镜规格", "4. 风格禁区"], size=28)

    box(draw, (650, 300, 1154, 768), fill=(255, 255, 255, 234), radius=30)
    draw.text((688, 338), "我交付", font=font(38, True), fill=(18, 24, 32))
    multiline(draw, (692, 418), ["1. 分镜模板", "2. 提示词SOP", "3. 样图建议", "4. 可选调试"], size=28)

    box(draw, (88, 836, 1154, 1148), fill=(8, 12, 22, 234), radius=34)
    draw.text((126, 876), "说明", font=font(40, True), fill=(255, 255, 255))
    multiline(
        draw,
        (130, 952),
        ["不做未授权小说/IP改编", "不接公众人物或侵权角色仿制", "AI出图需人工筛选和二次打磨"],
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
    title = "AI漫剧分镜工作流｜角色一致多宫格短剧分镜"
    body = """闲鱼上很多“AI短剧/漫剧分镜”卖的是低价资料包，但真正卡人的点是：角色不一致、场景乱跑、镜头没有节奏、宫格不能稳定复用。

我这边做的是 AI漫剧分镜工作流 / 角色一致多宫格分镜：把你的题材、剧本片段、角色设定，整理成可复用的分镜提示词、宫格模板和出图SOP。

可做：
1. 剧本拆镜：把文字拆成远景/中景/近景/特写等镜头
2. 多宫格分镜：9宫格、16宫格、25宫格思路梳理
3. 角色一致性：整理角色描述、三视图、表情组、服装和场景锁定词
4. 漫剧/小说推文：适合短剧号、小说推文、漫剧视频前期出图
5. 定制工作流：按你的题材做一套可复用SOP，方便后续批量生产

套餐：
9.9 元：分镜提示词包 + 宫格模板，含1次文字调整
59 元：给你的题材拆一版分镜流程 + 样图建议，含2次调整
199 元：定制角色一致分镜工作流 + SOP说明 + 调试建议，含3次调整

下单前请先私聊发：
题材/剧本片段、角色设定、想做9/16/25哪种宫格、参考风格、目标平台、不能出现的内容、是否需要我帮你调试工具。

说明：
不承诺爆款、收益、平台过审。
不做未授权小说/影视IP/动漫角色改编，不接侵权搬运。
AI分镜适合提高效率，最终画面仍需要人工筛选和二次打磨。
超过套餐内调整次数，可私聊按工作量补差价。"""
    config = {
        "title": title,
        "body": body,
        "price": "9.90",
        "originalPrice": "199",
        "noShipping": True,
        "imagePaths": [str(p) for p in paths],
    }
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    (OUT_DIR / "publish_config_nano_banana_storyboard.json").write_text(
        json.dumps(config, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    (ROOT / "publish_config_nano_banana_storyboard.json").write_text(
        json.dumps(config, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )


def write_pack(paths: list[Path]) -> None:
    md = """# AI漫剧分镜工作流上架包

## 标题

AI漫剧分镜工作流｜角色一致多宫格短剧分镜

## 核心定位

不做单纯资料搬运，而是卖可反复用的分镜生产流程：剧本拆镜、角色一致性、9/16/25宫格模板、样图反馈和定制SOP。

## 价格

- 9.9 元：分镜提示词包 + 宫格模板，含1次文字调整
- 59 元：题材拆镜流程 + 样图建议，含2次调整
- 199 元：定制角色一致分镜工作流 + SOP说明 + 调试建议，含3次调整

## 买家需要提供

题材/剧本片段、角色设定、宫格规格、参考风格、目标平台、风格禁区、是否需要调试工具。

## 边界

不承诺爆款、收益、平台过审；不做未授权小说/影视IP/动漫角色改编；AI分镜需要人工筛选和二次打磨；超过套餐内调整次数，可私聊按工作量补差价。

## 上架图

"""
    md += "\n".join(f"- {p}" for p in paths)
    md += "\n\n## 类目建议\n\n优先试 `AI图文工具/服务`，字段建议 `计价方式=元/次`、`输入类型=文生图/图生图`、`功能类型=图片制作/图片修改`。如果网页端拦截，再试 `AI提效工具`。\n"
    (OUT_DIR / "nano_banana_storyboard_publish_pack.md").write_text(md, encoding="utf-8")


def write_research_note() -> None:
    RESEARCH_DIR.mkdir(parents=True, exist_ok=True)
    note = """# AI漫剧分镜工作流需求依据

- Round 5 闲鱼站内验证：`AI短剧 分镜 工作流` 下出现 25/16/9 宫格 Coze 分镜工作流，约 2.88 元，71 人想要；同词下还有新版漫剧分镜、AI漫剧3+2工作流等重复商品。
- `角色一致性 分镜图 工作流` 下出现角色一致、人物场景统一、9/16/25宫格适配、AI漫剧角色提示词库等商品，其中角色提示词库出现 61 人想要。
- Jina 外部信号：Nano Banana 工作流内容提到动作迁移和分镜生成，分镜生成强调远景、中景、近景、特写等多角度宫格；AI 视频/漫剧生产链条近期持续被讨论。
- 复利逻辑：已发布的短剧剧本 Agent 可以导流到“剧本 -> 分镜 -> 视频”的下一环；本商品沉淀角色提示词、镜头词库、宫格模板、SOP和样图模板。
- Image2参考：参考用户 image2 案例库中的 UI 与界面、图表与信息图、商品与电商、海报与排版案例，底图用高质工具界面和信息图风格，中文卖点后期叠加。
"""
    (RESEARCH_DIR / "positioning.md").write_text(note, encoding="utf-8")


def build_images() -> list[Path]:
    return [cover(), script_to_grid(), consistency(), use_cases(), packages(), boundary()]


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
