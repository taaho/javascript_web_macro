# JavaScript Web Macro

Node.js와 Playwright로 Maxerve 예약 페이지의 일반 주차대행 선택 가능 여부를 반복 확인합니다.

## 동작 흐름

```text
JavaScript 코드
  ↓ Node.js가 실행
Playwright 라이브러리
  ↓ Chromium 실행 및 제어 연결
Chromium 브라우저
  ↓ 새 탭 생성
Playwright Page 객체
  ↓ goto, locator, press 등의 명령 실행
예약 페이지
```

`maxerve-monitor.mjs`는 JavaScript 파일입니다. Node.js가 이 파일을 실행하면 Playwright를 불러오고, `chromium.launch()`로 Playwright 전용 Chromium 브라우저를 실행합니다. `browser.newPage()`가 만든 탭은 Playwright의 `Page` 객체로 반환되며, `page.goto()`로 페이지를 열고 `page.locator()`와 `press()`로 화면 요소를 조작합니다.

## Windows 실행

Node.js 20 이상을 설치한 후 저장소 폴더에서 PowerShell로 실행합니다.

```powershell
.\run-maxerve-monitor.ps1
```

첫 실행 시 npm 의존성과 Chromium을 설치합니다. 별도 브라우저 창에서 날짜와 19시를 선택하고, 각 조작 사이에 2~3초 간격을 둡니다. 선택에 성공하면 반복을 멈추고 브라우저를 직접 사용할 수 있도록 유지합니다. 예약 신청은 자동으로 하지 않습니다. 중단하려면 실행 창에서 Ctrl+C를 누릅니다.

## 카카오톡 알림

일반 주차대행 선택에 성공하면 `send-kakao.ps1`을 실행하여 열린 `박유진` 대화창에 `바로 예약해`를 한 번 전송합니다. 카카오톡 로그인과 잠금 해제 상태가 필요하며 입력란은 비워 두세요. 정확히 일치하는 카카오톡 창과 입력란을 확인하고, 기존 초안이 있거나 창 활성화에 실패하면 전송하지 않습니다. 전송 실패 시 자동 재시도하지 않으며 예약 브라우저는 유지합니다. 전송 입력 완료는 상대방 수신을 보장하지 않습니다.

## 날짜 선택 방식

실행하면 이용 날짜 숫자(1~31)를 입력받습니다. `2`를 입력하면 **2026년 10월 2일 19시**, `26`을 입력하면 **2026년 10월 26일 19시**를 확인합니다. 잘못된 입력은 다시 입력받습니다. 연도·월·시간은 고정이며, 달력을 2026년 10월로 이동한 후 선택된 날짜가 목적 날짜와 일치하는지 확인합니다.

`maxerve-monitor.mjs`는 브라우저 제어 코드, `run-maxerve-monitor.ps1`은 설치 및 실행 도우미입니다. `package-lock.json`은 의존성 버전을 고정합니다. 설치된 의존성, 빌드 결과물, 스크린샷은 Git에서 제외합니다.
