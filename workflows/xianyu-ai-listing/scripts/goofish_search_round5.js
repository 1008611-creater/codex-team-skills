const fs = require("node:fs");
const path = require("node:path");

const playwrightModule =
  process.env.PLAYWRIGHT_MODULE ||
  path.join(process.env.TEMP || process.env.TMP || ".", "xianyu-pw", "node_modules", "playwright");
const { chromium } = require(playwrightModule);

const workspace = path.resolve(__dirname, "..");
const outDir = path.join(workspace, "output", "demand_radar", "round5_2026-05-22");
const rawDir = path.join(outDir, "goofish_raw");
fs.mkdirSync(rawDir, { recursive: true });

const queries = [
  "Nano Banana Pro 漫剧分镜",
  "GPT-Image-2 漫剧分镜",
  "AI短剧 分镜 工作流",
  "角色一致性 分镜图 工作流",
  "Seedance2 即梦 电商视频",
  "即梦 Seedance2 运镜提示词",
  "AI电商 产品图转视频",
  "数字人口播 带货 工作流",
  "OpenClaw Skill 安全检查",
  "恶意Skill 检测 OpenClaw",
  "OpenClaw 必装Skill 白名单",
  "AI图片 高清修复 Real-ESRGAN",
  "AI表情包 套图 定制",
  "AI小红书封面 作图",
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
    if (
      /人想要|¥|工作流|部署|教程|定制|AI|Image2|GPT|Nano|Banana|漫剧|分镜|短剧|角色一致|Seedance|即梦|产品图|视频|数字人|口播|OpenClaw|Skill|恶意|安全|高清|修复|Real-ESRGAN|表情包|小红书|封面/i.test(
        line,
      )
    ) {
      const start = Math.max(0, i - 3);
      const end = Math.min(lines.length, i + 9);
      const block = lines.slice(start, end).join(" / ");
      if (!signals.includes(block)) signals.push(block);
    }
    if (signals.length >= 36) break;
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
        return { text: text.slice(0, 320), href, price, wants };
      })
      .filter((item) => item.href && item.text && !/发闲置|消息|反馈|客服|登录/.test(item.text));
    const seen = new Set();
    return cards
      .filter((item) => {
        const key = item.href || item.text;
        if (seen.has(key)) return false;
        seen.add(key);
        return true;
      })
      .slice(0, 24);
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

  const summaryFile = path.join(outDir, "goofish_search_summary_round5.json");
  fs.writeFileSync(summaryFile, JSON.stringify(results, null, 2), "utf8");
  console.log(`SUMMARY ${summaryFile}`);
  await page.close().catch(() => {});
  await browser.close();
})();
