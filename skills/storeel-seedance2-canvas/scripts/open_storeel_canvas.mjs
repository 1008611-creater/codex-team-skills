import { chromium } from 'playwright';

const email = process.env.STOREEL_CANVAS_EMAIL;
const password = process.env.STOREEL_CANVAS_PASSWORD;
const projectUrl = process.env.STOREEL_CANVAS_PROJECT_URL;
const projectName = process.env.STOREEL_CANVAS_PROJECT_NAME || `AI video free canvas ${Date.now()}`;
const headless = (process.env.STOREEL_HEADLESS || 'false').toLowerCase() === 'true';
const chromePath = process.env.STOREEL_CHROME_PATH || 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';

if (!email || !password) {
  throw new Error('Missing STOREEL_CANVAS_EMAIL or STOREEL_CANVAS_PASSWORD.');
}

const browser = await chromium.launch({
  headless,
  executablePath: chromePath,
});
const page = await browser.newPage({ viewport: { width: 1512, height: 982 } });

await page.goto('https://canvas.storeel.vip/login/', { waitUntil: 'domcontentloaded', timeout: 60000 });
await page.locator('input[type="email"]').fill(email);
await page.locator('input[type="password"]').fill(password);
const checkbox = page.locator('input[type="checkbox"]');
if (!(await checkbox.isChecked())) await checkbox.check({ force: true });
await Promise.all([
  page.waitForLoadState('networkidle', { timeout: 60000 }).catch(() => {}),
  page.locator('button[type="submit"]').click(),
]);

await page.waitForTimeout(2000);
if (projectUrl) {
  await page.goto(projectUrl, { waitUntil: 'domcontentloaded', timeout: 60000 });
} else {
  await page.goto('https://canvas.storeel.vip/', { waitUntil: 'domcontentloaded', timeout: 60000 });
  await page.waitForLoadState('networkidle', { timeout: 60000 }).catch(() => {});
  const createText = page.locator('text=创作');
  const createCount = await createText.count();
  if (createCount >= 3) {
    await createText.nth(2).click();
  } else {
    await page.getByRole('button', { name: '开始创作' }).first().click();
  }
  await page.waitForTimeout(1000);
  const inputs = page.locator('input');
  await inputs.nth((await inputs.count()) - 1).fill(projectName);
  await Promise.all([
    page.waitForLoadState('domcontentloaded', { timeout: 60000 }).catch(() => {}),
    page.getByRole('button', { name: '创建', exact: true }).click(),
  ]);
  await page.waitForTimeout(3000);
  const modeButtons = page.getByText('选择该模式', { exact: true });
  if ((await modeButtons.count()) >= 2) {
    await modeButtons.nth(1).click();
    await page.waitForLoadState('networkidle', { timeout: 60000 }).catch(() => {});
  }
}

console.log(await page.title());
console.log(page.url());
console.log(projectName);
await browser.close();
