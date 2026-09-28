import { chromium } from "playwright";
import { execFile } from "node:child_process";
import { promisify } from "node:util";
import { fileURLToPath } from "node:url";

const runFile = promisify(execFile);
async function notifyKakao() {
  await runFile("powershell.exe", [
    "-NoProfile", "-STA", "-ExecutionPolicy", "Bypass", "-File", fileURLToPath(new URL("./send-kakao.ps1", import.meta.url)),
    "-ChatTitle", "박유진", "-Message", "바로 예약해",
  ], { windowsHide: true, timeout: 15000 });
}

const targetUrl = "https://maxerve-mparking.com/reserve/";
const unavailableText =
  "* 일반 주차대행 선택한 날짜의 발렛 이용한도가 초과하여 예약이 불가합니다.";

const sleepHuman = (page) =>
  page.waitForTimeout(2000 + Math.floor(Math.random() * 1001));

async function selectDay(page, day) {
  const date = page.locator("#use_date");
  await date.press("Control+Home");
  await sleepHuman(page);
  await date.press("PageDown");
  await sleepHuman(page);
  await page.getByRole("link", { name: day, exact: true }).press("Enter");
  await sleepHuman(page);
}

const browser = await chromium.launch({ headless: false });
const page = await browser.newPage();
await page.goto(targetUrl, { waitUntil: "domcontentloaded" });

try {
  for (;;) {
    await selectDay(page, "2");
    await page.locator("#use_hour").selectOption("19");
    await sleepHuman(page);

    const normalValet = page.getByRole("radio", {
      name: "일반 주차대행",
      exact: true,
    });
    const unavailable = page.getByText(unavailableText, { exact: true });

    if (await normalValet.isEnabled()) {
      await normalValet.press("Space");
      await sleepHuman(page);
    }

    const isAvailable =
      (await normalValet.isChecked()) &&
      (await normalValet.isEnabled()) &&
      !(await unavailable.isVisible());

    if (isAvailable) {
      console.log("예약 가능: 2026-10-02 19시 일반 주차대행이 선택되었습니다.");
      try {
        await notifyKakao();
        console.log("카카오톡 전송 입력 완료: 박유진 / 바로 예약해");
      } catch (error) {
        console.error("카카오톡 알림 실패. 중복 전송 방지를 위해 재시도하지 않습니다.", error.message);
      }
      console.log("반복 확인을 멈췄습니다. 열린 브라우저를 직접 사용하세요.");
      console.log("브라우저 사용이 끝날 때까지 이 실행 창을 닫지 마세요.");
      // Keep Playwright connected without further interaction until the user closes the browser.
      await new Promise((resolve) => {
        browser.once("disconnected", resolve);
        if (!browser.isConnected()) resolve();
      });
      break;
    }

    if (await unavailable.isVisible()) {
      await page.getByRole("button", { name: "확인", exact: true }).press("Enter");
    }
  }
} finally {
  await browser.close();
}
