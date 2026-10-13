import { Then, Given } from "@cucumber/cucumber";
import { expect } from "@playwright/test";
import { CustomWorld } from "./custom-world";

const BASE_URL = process.env.SERVICE_ENDPOINT || "http://localhost:3000";

Given("User navigates to the homepage", async function (this: CustomWorld) {
  await this.page.goto(BASE_URL);
});

Given("User navigates to the ingress homepage", async function (this: CustomWorld) {
  const ingressUrl = process.env.INGRESS_ENDPOINT;
  if (!ingressUrl) return "skipped";

  const response = await this.page.goto(ingressUrl);
  expect(response?.ok()).toBe(true);
});

Then("It should show the title {string}", async function (this: CustomWorld, expectedTitle: string) {
  await expect(this.page.locator("h1")).toContainText(expectedTitle);
});
