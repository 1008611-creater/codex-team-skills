const fs = require("node:fs");
const path = require("node:path");
const playwrightModule =
  process.env.PLAYWRIGHT_MODULE ||
  path.join(process.env.TEMP || process.env.TMP || ".", "xianyu-pw", "node_modules", "playwright");
const { chromium } = require(playwrightModule);

const workspace = path.resolve(__dirname, "..");
const outputDir = path.join(workspace, "output", "playwright");
fs.mkdirSync(outputDir, { recursive: true });

const target = process.argv[2] || "AI提效工具";

function log(...args) {
  console.log(new Date().toISOString(), ...args);
}

async function readDropdown(page) {
  return page.evaluate(() => {
    return [...document.querySelectorAll(".ant-select-dropdown, [class*='dropdown'], [role='listbox']")]
      .map((el) => {
        const r = el.getBoundingClientRect();
        return {
          text: (el.innerText || "").trim(),
          cls: String(el.className).slice(0, 160),
          visible: r.width > 0 && r.height > 0,
          x: Math.round(r.x),
          y: Math.round(r.y),
          w: Math.round(r.width),
          h: Math.round(r.height),
        };
      })
      .filter((item) => item.visible);
  });
}

(async () => {
  log("connect cdp");
  const browser = await chromium.connectOverCDP(`http://127.0.0.1:${process.env.GOOFISH_CDP_PORT || "9223"}`);
  const context = browser.contexts()[0];
  const page = context.pages().find((p) => p.url().includes("goofish.com/publish"));
  if (!page) throw new Error("No goofish publish page found");
  page.setDefaultTimeout(6000);
  await page.bringToFront();
  log("page", page.url());
  await page.evaluate(() => {
    window.scrollTo(0, 260);
  });
  await page.waitForTimeout(500);

  const selectBox = await page.evaluate(() => {
    const el = document.querySelector(".categoryList--lqyn7MJb .ant-select");
    if (!el) return null;
    const r = el.getBoundingClientRect();
    return { x: Math.round(r.x + r.width / 2), y: Math.round(r.y + r.height / 2), w: Math.round(r.width), h: Math.round(r.height) };
  });
  if (!selectBox) throw new Error("Cannot find category select");
  log("click category select", JSON.stringify(selectBox));
  await page.mouse.click(selectBox.x, selectBox.y);
  await page.waitForTimeout(800);
  log("dropdown open", JSON.stringify(await readDropdown(page), null, 2));

  const inputBox = await page.evaluate(() => {
    const el = document.querySelector(".categoryList--lqyn7MJb input[role='combobox']");
    if (!el) return null;
    const r = el.getBoundingClientRect();
    return { x: Math.round(r.x + r.width / 2), y: Math.round(r.y + r.height / 2), w: Math.round(r.width), h: Math.round(r.height) };
  });
  if (inputBox) {
    log("type target", target, JSON.stringify(inputBox));
    await page.mouse.click(inputBox.x, inputBox.y);
    await page.keyboard.press("Control+A");
    await page.keyboard.type(target, { delay: 20 });
  } else {
    log("no combobox input; typing on focused element");
    await page.keyboard.type(target, { delay: 20 });
  }
  await page.waitForTimeout(1500);

  let dropdown = await readDropdown(page);
  console.log("dropdown after search", JSON.stringify(dropdown, null, 2));

  const option = await page.evaluate((targetText) => {
    const els = [...document.querySelectorAll(".ant-select-item-option, [role='option'], .ant-select-dropdown *")];
    const found = els
      .map((el) => {
        const r = el.getBoundingClientRect();
        return {
          text: (el.innerText || "").replace(/\s+/g, " ").trim(),
          cls: String(el.className),
          x: Math.round(r.x + r.width / 2),
          y: Math.round(r.y + r.height / 2),
          w: Math.round(r.width),
          h: Math.round(r.height),
          visible: r.width > 0 && r.height > 0,
        };
      })
      .filter((item) => item.visible && item.text.includes(targetText))
      .sort((a, b) => a.text.length - b.text.length)[0];
    return found || null;
  }, target);
  log("matched option", JSON.stringify(option, null, 2));
  if (!option) throw new Error(`Cannot find category option: ${target}`);
  const locatorOption = page.locator(".ant-select-dropdown .ant-select-item-option").filter({ hasText: target }).last();
  if ((await locatorOption.count().catch(() => 0)) > 0) {
    await locatorOption.click({ force: true });
  } else {
    await page.evaluate((targetText) => {
      const el = [...document.querySelectorAll(".ant-select-item-option")]
        .find((item) => (item.innerText || "").includes(targetText));
      if (el instanceof HTMLElement) el.click();
    }, target);
    await page.mouse.click(option.x, option.y);
  }

  await page.waitForTimeout(1200);
  const state = await page.evaluate(() => {
    const categoryText = document.querySelector(".categoryList--lqyn7MJb")?.innerText || "";
    const warning = [...document.querySelectorAll("*")]
      .map((el) => (el.innerText || "").trim())
      .find((text) => /网页版暂不支持发布此分类|不支持发布/.test(text));
    const publishButtons = [...document.querySelectorAll("button")]
      .map((button, index) => {
        const r = button.getBoundingClientRect();
        return {
          index,
          text: button.innerText.trim(),
          disabled: button.disabled,
          visible: r.width > 0 && r.height > 0,
          cls: String(button.className).slice(0, 140),
        };
      })
      .filter((item) => item.visible);
    return { categoryText, warning, publishButtons };
  });
  const shot = path.join(outputDir, "goofish_category_ai_tool.png");
  await page.screenshot({ path: shot, fullPage: false });
  console.log(JSON.stringify({ target, state, shot }, null, 2));
  await browser.close();
})().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
