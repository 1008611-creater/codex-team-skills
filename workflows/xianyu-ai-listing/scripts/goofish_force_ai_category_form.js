const fs = require("node:fs");
const path = require("node:path");
const playwrightModule =
  process.env.PLAYWRIGHT_MODULE ||
  path.join(process.env.TEMP || process.env.TMP || ".", "xianyu-pw", "node_modules", "playwright");
const { chromium } = require(playwrightModule);

const workspace = path.resolve(__dirname, "..");
const outputDir = path.join(workspace, "output", "playwright");
fs.mkdirSync(outputDir, { recursive: true });

(async () => {
  const browser = await chromium.connectOverCDP(`http://127.0.0.1:${process.env.GOOFISH_CDP_PORT || "9223"}`);
  const context = browser.contexts()[0];
  const page = context.pages().find((p) => p.url().includes("goofish.com/publish"));
  if (!page) throw new Error("No publish page");
  await page.bringToFront();

  const out = await page.evaluate(() => {
    const el = document.querySelector(".categoryList--lqyn7MJb .ant-select");
    const fiberKey = Object.keys(el || {}).find((key) => key.startsWith("__reactFiber"));
    let fiber = fiberKey ? el[fiberKey] : null;
    let form = null;
    let ai = null;
    for (let i = 0; fiber && i < 60; i += 1, fiber = fiber.return) {
      const props = fiber.memoizedProps || {};
      if (!ai && Array.isArray(props.options)) {
        ai = props.options.find((option) => option.value === "202156031" || option.label === "AI图文工具/服务");
      }
      if (!form && props.value && props.value.form) form = props.value.form;
    }
    if (!form || !ai) return { ok: false, hasForm: Boolean(form), hasAi: Boolean(ai) };

    const data = ai.data || ai;
    const transport = data.transportData || {};
    const value = data.value || ai.value || "202156031";
    const label = data.label || ai.label || "AI图文工具/服务";
    const item = {
      ...transport,
      channelCateName: data.channelCateName || label,
      channelCateId: data.channelCateId || value,
      tbCatId: data.tbCatId || transport.tbCatId || null,
      propertyName: "分类",
      propertyId: "-10000",
      from: data.from || "newPublishChoice",
      labelFrom: "newPublish",
      isUserClick: "1",
      text: label,
      properties: `-10000##分类:${value}##${label}`,
    };

    form.setFieldsValue({ itemLabelExtList: [item] });
    return { ok: true, item, fields: form.getFieldsValue(true).itemLabelExtList };
  });

  await page.waitForTimeout(1500);
  const state = await page.evaluate(() => {
    const categoryText = document.querySelector(".categoryList--lqyn7MJb")?.innerText || "";
    const body = document.body.innerText || "";
    const formFields = (() => {
      const el = document.querySelector(".categoryList--lqyn7MJb .ant-select");
      const fiberKey = Object.keys(el || {}).find((key) => key.startsWith("__reactFiber"));
      let fiber = fiberKey ? el[fiberKey] : null;
      for (let i = 0; fiber && i < 60; i += 1, fiber = fiber.return) {
        const props = fiber.memoizedProps || {};
        if (props.value && props.value.form) return props.value.form.getFieldsValue(true).itemLabelExtList;
      }
      return null;
    })();
    const publish = [...document.querySelectorAll("button")]
      .map((button, index) => {
        const r = button.getBoundingClientRect();
        return {
          index,
          text: button.innerText.trim(),
          disabled: button.disabled,
          visible: r.width > 0 && r.height > 0,
          cls: String(button.className),
        };
      })
      .filter((item) => item.visible && item.text.includes("发布"));
    return {
      categoryText,
      unsupported: /网页版暂不支持发布此分类/.test(body),
      formFields,
      publish,
    };
  });

  const shot = path.join(outputDir, "goofish_form_force_ai_category.png");
  await page.screenshot({ path: shot, fullPage: false });
  console.log(JSON.stringify({ out, state, shot }, null, 2));
  await browser.close();
})().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
