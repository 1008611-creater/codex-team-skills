const fs = require("node:fs");
const path = require("node:path");

const playwrightModule =
  process.env.PLAYWRIGHT_MODULE ||
  path.join(process.env.TEMP || process.env.TMP || ".", "xianyu-pw", "node_modules", "playwright");
const { chromium } = require(playwrightModule);

const workspace = path.resolve(__dirname, "..");
const outDir = path.join(workspace, "output", "demand_radar", "round4_2026-05-22");
const rawDir = path.join(outDir, "goofish_raw");
fs.mkdirSync(rawDir, { recursive: true });

const queries = [
  "AI视频人物替换",
  "动作迁移工作流",
  "Wan2.2 Animate 工作流",
  "AI电商模特换装",
  "AI一键生成服装场景图",
  "AI商品图 生成",
  "AI高清修复 图片",
  "男生展示面 AI",
  "韩国棒球 AI 照片",
  "AI旅行照 朋友圈",
  "前任Skill 部署",
  "龙虾 skill 部署",
  "OpenClaw 技能",
  "AI Agent Skill 定制",
  "AI工具站 定制",
  "Image2 同款图",
  "AI短剧剧本 生成",
  "ComfyUI 工作流 合集",
];

function compactLines(text) {
  return text
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter(Boolean);
}

function slugify(input) {
  return input
    .replace(/[^\p{L}\p{N}]+/gu, "_")
    .replace(/^_+|_+$/g, "")
    .slice(0, 64);
}

function extractSignals(lines) {
  const signals = [];
  for (let i = 0; i < lines.length; i += 1) {
    const line = lines[i];
    if (/人想要|¥|工作流|部署|教程|定制|AI|ComfyUI|Image2|棒球|展示面|矩阵|高清|修复|短剧|换装|场景图|Agent|Skill|OpenClaw|龙虾|动作迁移|人物替换/i.test(line)) {
      const start = Math.max(0, i - 3);
      const end = Math.min(lines.length, i + 9);
      const block = lines.slice(start, end).join(" / ");
      if (!signals.includes(block)) signals.push(block);
    }
    if (signals.length >= 30) break;
  }
  return signals;
}

async function extractCards(page) {
  return page.evaluate(() => {
    const anchors = [...document.querySelectorAll('a[href*="/item"], a[href*="item?id"]')];
    const cards = anchors
      .map((anchor) => {
        const container =
          anchor.closest("[class*='feeds-item'], [class*='card'], [class*='item'], [class*='Card']") ||
          anchor.parentElement;
        const text = (container?.innerText || anchor.innerText || "").replace(/\s+/g, " ").trim();
        const href = anchor.href || "";
        const price = text.match(/¥\s*([0-9]+(?:\.[0-9]+)?)/)?.[1] || null;
        const wants = text.match(/([0-9]+)\s*人想要/)?.[1] || null;
        return { text: text.slice(0, 260), href, price, wants };
      })
      .filter((item) => item.href && item.text && !/发闲置|消息|反馈|客服/.test(item.text));
    const seen = new Set();
    return cards.filter((item) => {
      const key = item.href || item.text;
      if (seen.has(key)) return false;
      seen.add(key);
      return true;
    }).slice(0, 20);
  });
}

(async () => {
  const port = process.env.GOOFISH_CDP_PORT || "9223";
  const browser = await chromium.connectOverCDP(`http://127.0.0.1:${port}`);
  const context = browser.contexts()[0];
  const page = await context.newPage();
  page.setDefaultTimeout(15000);
  const results = [];

  for (const query of queries) {
    const url = `https://www.goofish.com/search?q=${encodeURIComponent(query)}`;
    await page.goto(url, { waitUntil: "domcontentloaded", timeout: 60000 });
    await page.waitForTimeout(4500);
    await page.evaluate(() => window.scrollTo(0, document.body.scrollHeight / 3)).catch(() => {});
    await page.waitForTimeout(1200);
    await page.evaluate(() => window.scrollTo(0, document.body.scrollHeight / 1.8)).catch(() => {});
    await page.waitForTimeout(1200);

    const text = await page.locator("body").innerText({ timeout: 15000 }).catch(() => "");
    const lines = compactLines(text);
    const signals = extractSignals(lines);
    const cards = await extractCards(page).catch(() => []);
    const screenshot = path.join(rawDir, `${slugify(query)}.png`);
    await page.screenshot({ path: screenshot, fullPage: false }).catch(() => {});

    const file = path.join(rawDir, `${slugify(query)}.txt`);
    fs.writeFileSync(file, lines.join("\n"), "utf8");
    const item = { query, url, signals, cards, rawTextFile: file, screenshot };
    results.push(item);
    console.log(`SNAPSHOT ${query} -> ${file} cards=${cards.length} signals=${signals.length}`);
  }

  const summaryFile = path.join(outDir, "goofish_search_summary_round4.json");
  fs.writeFileSync(summaryFile, JSON.stringify(results, null, 2), "utf8");
  console.log(`SUMMARY ${summaryFile}`);
  await page.close().catch(() => {});
  await browser.close();
})();
