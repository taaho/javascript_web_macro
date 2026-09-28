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

### 카카오톡 전송 호출 흐름

카카오 서버의 메시지 API를 직접 호출하지 않고, PC에 열린 카카오톡 창을 Windows 기능으로 조작합니다. 로그인된 카카오톡 앱이 실제 메시지를 서버로 전달하므로 별도의 카카오 API 키가 필요하지 않습니다.

```text
JavaScript에서 예약 가능 상태 감지
  ↓ notifyKakao()
Node.js execFile()로 powershell.exe 실행
  ↓ send-kakao.ps1
Windows UI Automation으로 '박유진' 창과 KakaoTalk 프로세스 확인
  ↓ Windows API로 창 복원 및 활성화
메시지 입력란 확인 및 포커스 설정
  ↓ 클립보드에 '바로 예약해' 저장 → Ctrl+V
입력 내용과 포커스 검증
  ↓ Enter 입력
입력란이 비워졌는지 확인
```

| 코드/API | 역할 |
|---|---|
| `execFile("powershell.exe", ...)` | JavaScript에서 PowerShell 전송 스크립트 실행 |
| `UIAutomationClient` | 창 제목, 프로세스, 입력란을 찾아 상태 확인 |
| `ShowWindow()` | 최소화된 대화창 복원 |
| `SetForegroundWindow()` | 대화창을 앞으로 가져오기 |
| `AttachThreadInput()` / `BringWindowToTop()` | 기본 활성화 실패 시 입력 스레드를 임시 연결해 활성화 재시도; 이후 연결 해제 |
| `ValuePattern` | 입력란의 읽기 전용 여부와 입력 내용 확인 |
| `Clipboard.SetText()` | 보낼 문구를 클립보드에 저장 |
| `SendKeys.SendWait('^v')` | 실제 붙여넣기 입력으로 메시지 작성 |
| `SendKeys.SendWait('{ENTER}')` | Enter 키로 전송 실행 |

입력값을 직접 설정하는 `ValuePattern.SetValue()`는 카카오톡의 전송 버튼을 활성화하지 못해, 실제 붙여넣기 입력으로 변경했습니다. 빈 입력란에서 반환되는 안내 문구 `메시지 입력`과 줄바꿈도 빈 상태로 처리합니다. 붙여넣기 후 클립보드가 여전히 보낸 문구이면 이전 클립보드를 복원합니다.

스크립트는 지정한 창과 입력 포커스를 확인한 뒤 전송하고, 전송 후 입력란이 비워졌는지 검사합니다. 이는 상대방의 수신이나 읽음 여부를 확인하는 기능은 아닙니다. 실패 시 중복 전송을 피하기 위해 자동으로 재시도하지 않습니다.

## 날짜 선택 방식

실행하면 이용 날짜 숫자(1~31)를 입력받습니다. `2`를 입력하면 **2026년 10월 2일 19시**, `26`을 입력하면 **2026년 10월 26일 19시**를 확인합니다. 잘못된 입력은 다시 입력받습니다. 연도·월·시간은 고정이며, 달력을 2026년 10월로 이동한 후 선택된 날짜가 목적 날짜와 일치하는지 확인합니다.

`maxerve-monitor.mjs`는 브라우저 제어 코드, `run-maxerve-monitor.ps1`은 설치 및 실행 도우미입니다. `package-lock.json`은 의존성 버전을 고정합니다. 설치된 의존성, 빌드 결과물, 스크린샷은 Git에서 제외합니다.
