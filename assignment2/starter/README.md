# 과제 2 신청 승인 서비스 시작 코드

신청·대기 취소·직접 승인·승인 취소·대기열 자동 승급·변경 이력을 구현합니다. 상위 폴더의 [안내문](../01_과제2_안내문.pdf)과 [API 계약](docs/API.md)을 먼저 읽으세요.

**제출 마감: 2026년 11월 25일 23:59 (한국 시간)**

## 실행

Node.js **24.x**와 npm이 필요합니다. Node.js 20은 지원하지 않습니다. SQLite는 Node 내장 모듈입니다.

```sh
node --version
npm ci
npm test
npm start
```

http://127.0.0.1:3000 에 접속합니다. Ctrl+C로 종료합니다.

- 포트 사용 중: 기존 실행 터미널을 종료하거나 다른 포트를 사용합니다.
- macOS / Linux: `PORT=3001 npm start`
- Windows PowerShell: `$env:PORT="3001"; npm start`
- 첫 실행: `data/app.sqlite`와 `data/jwt-secret.txt`가 자동 생성됩니다.
- 브라우저 로그인 토큰은 메모리에만 저장합니다. 새로고침 후 다시 로그인하세요. DB 데이터는 유지됩니다.

## 연습 계정

공통 비밀번호는 `Classroom123!`입니다. 실제 이용자가 아닌 가상 계정입니다.

|아이디|이름|역할|
|---|---|---|
|alice|민지|학생|
|bob|준호|학생|
|charlie|서연|학생|
|manager1|운영자 A|행사 1 담당 · 정원 2명|
|manager2|운영자 B|행사 2 담당 · 정원 1명|

로그인 화면의 계정 버튼으로 입력값을 채우고 로그인 버튼을 누릅니다. 각 탭은 별도 토큰을 사용하므로 일반 탭 여러 개로 역할을 나눌 수 있습니다.

## 제공 코드와 구현할 부분

로그인·JWT 인증, 스키마와 가상 계정, 조회 API와 권한 검사, 입력 형식 검사, 기본 화면, SQL 조회·저장 도구를 제공합니다.

`src/application-service.js`의 TODO 4개는 초기 상태에서 501을 반환합니다.

1. `apply`: 행사·학생·중복 검사, PENDING 저장과 APPLY 이력
2. `cancel`: 학생 본인의 PENDING 취소, CANCELLED와 CANCEL 이력
3. `approve`: 담당자·상태·정원 검사, APPROVED와 APPROVE 이력
4. `revoke`: 담당자의 승인 취소, 다음 대기자 1명 승급, 두 이력의 원인 연결

모든 상태 변경과 이력 저장을 트랜잭션으로 묶으세요. 특히 revoke에서는 신청 2건과 이력 2건의 부분 저장을 막아야 합니다. 대기자 선택, 업무 규칙, 이력 저장 시점, 트랜잭션 경계는 학생 구현입니다. repository 함수 자체는 권한을 검사하지 않습니다. 보조 함수·SQL·파일은 필요하면 추가할 수 있습니다.

## 테스트

```sh
npm test
npm run test:assignment
npm run test:advanced
```

- `npm test`: 제공 기반 기능 4개. 구현 전과 후 모두 통과해야 합니다.
- `test:assignment`: 필수 32개. TODO 구현 전 일부 실패가 정상입니다.
- `test:advanced`: 선택 심화. 서버 2개가 마지막 자리를 동시에 승인하는 검사를 20회 수행합니다. 미수행은 감점하지 않습니다.

테스트는 별도 임시 DB·포트를 사용합니다. 필수 테스트 T28~T30은 임시 DB 트리거로 이력 저장 실패를 주입합니다. `TEST_INJECTED_FAILURE` 로그는 이 검사의 의도된 오류입니다. HTTP 500뿐 아니라 상태·이력 전체가 요청 전과 같은지 검사합니다. 테스트가 오류를 흉내 내므로 실제 서비스 코드에 특별 처리를 넣지 마세요. 기대값 변경이나 테스트 삭제는 허용하지 않습니다.

## 화면 검증

- U01: alice 신청 → manager1 승인 → 학생이 최신 상태 확인.
- U02: 운영자가 대기 목록 조회 → 학생이 대기 취소 → 오래된 운영자 화면의 승인 거부(409)와 CANCELLED 유지.
- U03: 서버 종료·재실행 → 재로그인 → 신청 상태와 이력 유지.
- U04: 새 DB에서 행사 2에 alice·bob·charlie 순서로 신청 → manager2가 alice 승인 → alice 승인 취소(사유 입력) → bob 자동 승인, charlie 대기 유지 → alice와 bob의 변경 이력에서 원인 ID 연결 확인.
- U05: 새 DB에서 alice만 행사 2 신청·승인 → 승인 취소 → REVOKED, 승인 인원 0명, 응답 promoted=null 확인.

승인 취소는 담당 운영자 화면의 승인된 신청에서 수행합니다. 각 신청의 ‘변경 이력 보기’로 저장 결과를 확인합니다. 다른 탭의 변경은 자동 반영되지 않으므로 ‘최신 정보 새로고침’을 사용하세요.

## DB 초기화와 이전 코드에서의 전환

서버를 먼저 종료하고 아래 명령에서 `RESET`을 입력합니다. 신청·변경 이력을 지우고 초기 계정·행사를 다시 만듭니다.

```sh
npm run db:reset
```

이전 배포본 DB에는 REVOKED 상태와 변경 이력 스키마가 없습니다. 새 배포본에서는 기존 DB를 초기화하세요. 운영 데이터 마이그레이션은 이 과제 범위가 아닙니다.

선택 환경변수: PORT, DB_PATH, JWT_SECRET. 기본 실행에는 설정 파일이 필요 없습니다. 키 파일을 지우면 기존 토큰은 무효화됩니다.

## 파일 구조

- `src/application-service.js`: 학생 구현 TODO 4개와 트랜잭션
- `src/repository.js`: 조회·저장·이력 저장 도구
- `src/db.js`: SQLite 스키마·초기 데이터
- `src/auth.js`: JWT 인증
- `src/app.js`: 라우팅·형식 검사·조회 권한·오류 응답
- `src/server.js`: 로컬 서버
- `public/`: 승인 취소·이력 조회 포함 제공 화면
- `tests/`: 기반·필수·선택 심화 테스트
- `docs/API.md`: 상태·이력·입출력 계약

## 제출 전 작성할 내용

이 부분을 본인의 서비스 소개, 변경 파일, 구현 완료 여부, 실행 환경, 알려진 문제, 보고서·검증 증거 링크와 AI 사용 요약으로 바꾸세요. GitHub URL·커밋 SHA를 LMS에 제출하고 보고서 PDF를 저장소 `docs/report.pdf`와 LMS에 같은 버전으로 첨부합니다.

`node_modules`, 생성 DB·서명 키, 실제 `.env`·JWT와 개인 정보는 제출하지 않습니다. 제공 코드와 직접 구현한 부분을 구분합니다.

## 참고 문서

- [Node.js SQLite](https://nodejs.org/docs/latest-v24.x/api/sqlite.html)
- [Express API](https://expressjs.com/en/5x/api/)
- [jsonwebtoken](https://github.com/auth0/node-jsonwebtoken)
