# JavaScript Web Macro

Node.js와 Playwright로 Maxerve 예약 페이지의 일반 주차대행 선택 가능 여부를 반복 확인합니다.

## Windows 실행

Node.js 20 이상을 설치한 후 저장소 폴더에서 PowerShell로 실행합니다.

```powershell
.\run-maxerve-monitor.ps1
```

첫 실행 시 npm 의존성과 Chromium을 설치합니다. 별도 브라우저 창에서 날짜와 19시를 선택하고, 각 조작 사이에 2~3초 간격을 둡니다. 선택에 성공하면 반복을 멈추고 브라우저를 직접 사용할 수 있도록 유지합니다. 예약 신청은 자동으로 하지 않습니다. 중단하려면 실행 창에서 Ctrl+C를 누릅니다.

## 날짜 선택 방식

현재 코드는 오늘 날짜에서 다음 달로 이동한 뒤 2일을 선택합니다. **2026년 9월에 실행해야 2026년 10월 2일을 선택합니다.** 다른 시기에 실행하려면 날짜 선택 코드를 수정해야 합니다.

`maxerve-monitor.mjs`는 브라우저 제어 코드, `run-maxerve-monitor.ps1`은 설치 및 실행 도우미입니다. `package-lock.json`은 의존성 버전을 고정합니다. 설치된 의존성, 빌드 결과물, 스크린샷은 Git에서 제외합니다.
