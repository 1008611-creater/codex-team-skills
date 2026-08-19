import { readFile } from "node:fs/promises";
import { chromium } from "playwright-core";

const REQUIRED_MODEL = "seedance2.5";
const REQUIRED_DURATION_SECONDS = 30;

function fail(error_code, error_message) {
  process.stdout.write(JSON.stringify({ ok: false, error_code, error_message }));
  process.exitCode = 1;
}

async function selectAccountPage(browser, accountSlot, pageUrlFragment) {
  const pages = browser.contexts().flatMap((context) => context.pages());
  const shell = pages.find((page) => page.url().startsWith("file:"));
  if (!shell) throw new Error("International Doubao account selector is not attached to CDP.");

  const openButtons = shell.getByRole("button", { name: "打开", exact: true });
  if (await openButtons.count() < accountSlot) {
    throw new Error(`Requested account_slot ${accountSlot} is unavailable.`);
  }
  const existingPages = new Set(pages);
  await openButtons.nth(accountSlot - 1).click({ timeout: 10000 });

  const deadline = Date.now() + 10000;
  while (Date.now() < deadline) {
    const candidate = browser.contexts().flatMap((context) => context.pages()).find(
      (page) => page.url().includes(pageUrlFragment) && !existingPages.has(page),
    );
    if (candidate) return candidate;
    await shell.waitForTimeout(250);
  }
  const activePage = browser.contexts().flatMap((context) => context.pages()).find(
    (page) => page.url().includes(pageUrlFragment),
  );
  if (!activePage) throw new Error("Dola account page did not open.");
  return activePage;
}

async function enforceSeedance25_30Seconds(page, workflow) {
  if (workflow?.model !== REQUIRED_MODEL || workflow?.duration_seconds !== REQUIRED_DURATION_SECONDS) {
    throw new Error("Manifest violates the fixed Seedance 2.5 / 30 second contract.");
  }
  const seedance20 = page.getByLabel("Seedance 2.0 使用 15 秒", { exact: true });
  const seedance25 = page.getByLabel("Seedance 2.5 使用 30 秒", { exact: true });
  if (await seedance20.count() !== 1 || await seedance25.count() !== 1) {
    throw new Error("Dola model-duration controls were not found.");
  }
  if (await seedance20.isChecked()) await seedance20.uncheck();
  if (!await seedance25.isChecked()) await seedance25.check();
  if (await seedance20.isChecked() || !await seedance25.isChecked()) {
    throw new Error("Dola did not retain the required Seedance 2.5 / 30 second configuration.");
  }
}

async function uploadMedia(page, inputs) {
  if (!inputs.length) return;
  const mediaInput = page.locator('input[type="file"][accept*=".jpg"]').first();
  if (await mediaInput.count() !== 1) {
    throw new Error("Dola combined image/video/audio input was not found.");
  }
  await mediaInput.setInputFiles(inputs.map((asset) => asset.path));
}

const index = process.argv.indexOf("--manifest");
if (index < 0 || !process.argv[index + 1]) {
  fail("DOLA_MANIFEST_REQUIRED", "Missing --manifest path.");
} else {
  const manifest = JSON.parse(await readFile(process.argv[index + 1], "utf8"));
  let browser;
  try {
    browser = await chromium.connectOverCDP(manifest.cdp_endpoint, { timeout: 5000 });
  } catch {
    fail("DOLA_CDP_UNAVAILABLE", "Start International Doubao with --remote-debugging-port and expose the configured DOLA_CDP_ENDPOINT.");
    process.exit();
  }

  try {
    const page = await selectAccountPage(browser, manifest.account_slot, manifest.page_url_fragment);

    await page.getByRole("tab", { name: "视频" }).click({ timeout: 10000 });
    await enforceSeedance25_30Seconds(page, manifest.workflow);
    await uploadMedia(page, manifest.inputs);
    const editor = page.locator("[contenteditable='true']").last();
    await editor.fill(manifest.prompt, { timeout: 10000 });

    const pageUrls = async () => {
      const text = await page.locator("body").innerText();
      const visibleUrls = text.match(/https?:\/\/[^\s"']+/g) || [];
      const mediaUrls = await page.locator("video[src], source[src], a[href]").evaluateAll((elements) =>
        elements.map((element) => element.getAttribute("src") || element.getAttribute("href")).filter(Boolean),
      );
      return [...visibleUrls, ...mediaUrls];
    };
    const existingUrls = new Set(await pageUrls());
    await page.locator("#flow-end-msg-send").click({ timeout: 10000 });
    await page.waitForTimeout(3000);
    const deadline = Date.now() + manifest.poll_seconds * 1000;
    while (Date.now() < deadline) {
      const outputUrl = (await pageUrls()).find(
        (url) => url.includes("v16-dola.dola.com") && !existingUrls.has(url),
      );
      if (outputUrl) {
        process.stdout.write(JSON.stringify({ ok: true, output_url: outputUrl }));
        await browser.close();
        process.exit();
      }
      await page.waitForTimeout(5000);
    }
    throw new Error("Dola result URL did not appear before timeout.");
  } catch (error) {
    fail("DOLA_AUTOMATION_FAILED", error instanceof Error ? error.message : "Unknown Dola automation failure.");
  } finally {
    await browser?.close();
  }
}
