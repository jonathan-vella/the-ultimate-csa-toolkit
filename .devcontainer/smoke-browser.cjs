const assert = require("node:assert/strict");
const path = require("node:path");
const { chromium } = require("playwright");
const puppeteer = require("puppeteer");

async function render(browser, output) {
  try {
    const page = await browser.newPage();
    await page.setContent("<h1>Azure Linux toolkit</h1>");
    assert.equal(await page.$eval("h1", (element) => element.textContent), "Azure Linux toolkit");
    await page.screenshot({ path: output });
  } finally {
    await browser.close();
  }
}

(async () => {
  const output = process.argv[2];
  assert.ok(output, "An output directory is required");
  await render(await chromium.launch({ chromiumSandbox: true }), path.join(output, "playwright.png"));
  await render(await puppeteer.launch(), path.join(output, "puppeteer.png"));
  console.log("Sandboxed Playwright and Puppeteer DOM/screenshots passed");
})().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
