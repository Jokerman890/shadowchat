const { expect, test } = require("@playwright/test");

const targetUrl =
  process.env.ENVIRONMENT_URL ||
  process.env.BASE_URL ||
  "https://shadowchat-preview.example.invalid";

const obviousErrorTitle =
  /^(?:404\b|page not found\b|not found\b|application error\b|internal server error\b)/i;
const obviousErrorHeading =
  /^(?:404(?:\s*[-:]\s*)?(?:error|page not found|not found)?|page not found|not found|application error|internal server error)$/i;

test("ShadowChat preview exposes required browser metadata", async ({ page }) => {
  const response = await page.goto(targetUrl, { waitUntil: "domcontentloaded" });

  expect(response, "initial navigation response").not.toBeNull();
  expect(response.status(), "initial HTTP status").toBeLessThan(400);

  await expect(page).toHaveTitle(/Shadow\s?Chat/i);

  const description = page.locator('meta[name="description"]');
  await expect(description).toHaveCount(1);
  await expect(description).toHaveAttribute("content", /\S+/);

  for (const property of ["og:title", "og:description", "og:url"]) {
    const tag = page.locator(`meta[property="${property}"]`);
    await expect(tag).toHaveCount(1);
    await expect(tag).toHaveAttribute("content", /\S+/);
  }

  const body = page.locator("body");
  await expect(body).toBeVisible();
  await expect(body).toContainText(/\S+/);

  await expect(page).not.toHaveTitle(obviousErrorTitle);
  await expect(body).not.toHaveText(obviousErrorHeading);
  await expect(
    page
      .locator('h1, [role="heading"][aria-level="1"]')
      .filter({ hasText: obviousErrorHeading }),
  ).toHaveCount(0);
});
