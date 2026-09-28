import { readFile } from "node:fs/promises";

export async function prefillReservation(page, selectDay, pause) {
  const details = JSON.parse(await readFile(new URL("./reservation.local.json", import.meta.url), "utf8"));
  if (!details.carNumber || !/^\d{11}$/.test(details.phone)) {
    throw new Error("reservation.local.json의 차량번호와 연락처를 확인하세요.");
  }
  for (const [selector, label] of [
    ["#car_type", "일반"], ["#moter_type", "현대"],
    ["#car_model", "그랜저"], ["#car_color", "검정색"],
  ]) {
    await page.locator(selector).selectOption({ label });
    await pause(page);
  }
  await page.locator("#car_number").fill(details.carNumber);
  await pause(page);
  await selectDay(page, "10", "#in_date", "2026-10-10");
  for (const [selector, value] of [["#in_hour", "21"], ["#in_minute", "30"]]) {
    await page.locator(selector).selectOption(value);
    await pause(page);
  }
  await page.locator("#in_air").fill("TW502");
  await pause(page);
  await page.locator("#client_phone").fill(details.phone);
  await pause(page);
  await page.locator("#policy_check").check();
  await pause(page);
  await page.locator("#uae_check").check();
  await pause(page);
}
