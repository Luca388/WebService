# 웹서비스설계 한국어 분반 과제 2 · 신청 승인 서비스

신청·대기 취소·직접 승인·승인 취소·대기열 자동 승급·변경 이력을 트랜잭션으로 구현한 개인 과제입니다.

## 제출물 위치

|항목|위치|
|---|---|
|소스와 실행·초기화 방법, 변경 파일, 구현 완료 여부|[starter/README.md](starter/README.md)|
|보고서 PDF|[starter/docs/report.pdf](starter/docs/report.pdf)|
|보고서 3~6장 검증 증거와 수집 스크립트|[starter/docs/evidence/](starter/docs/evidence/)|
|API 계약|[starter/docs/API.md](starter/docs/API.md)|
|의존성 고정|[starter/package-lock.json](starter/package-lock.json)|

## 빠른 실행

```sh
cd assignment2/starter
npm ci
echo RESET | npm run db:reset
npm run test:assignment
npm start   # http://127.0.0.1:3000
```

Node.js 24.x가 필요합니다. 자세한 내용은 [starter/README.md](starter/README.md)를 보세요.

수업 배포 자료(과제 안내문 PDF, 보고서 양식 docx)는 저장소에 포함하지 않았습니다.
