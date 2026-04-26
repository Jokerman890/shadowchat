const { expect, test } = require("@playwright/test");

const targetUrl =
  process.env.ENVIRONMENT_URL ||
  process.env.BASE_URL ||
  "https://shadowchat-preview.example.invalid";

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

  await expect(page.locator("body")).toBeVisible();
  await expect(page.locator("body")).toContainText(/\S+/);
  await expect(page.locator("body")).not.toContainText(
    /404|not found|application error|internal server error/i,
  );
});
