# CRUD Backend

Spring Boot로 구현한 상품 CRUD REST API 과제입니다. 데이터베이스 대신 Java의 `Map`을 임시 저장소로 사용했습니다.

## 개발 환경

- Java 21
- Spring Boot 4.1.1
- Gradle
- Lombok

## CRUD API

| Method | URL | 설명 |
|---|---|---|
| GET | `/api/v1/items` | 전체 상품 조회 |
| GET | `/api/v1/items/{id}` | ID로 상품 조회 |
| POST | `/api/v1/items` | 상품 생성 |
| POST | `/api/v1/items/sample` | 샘플 상품 생성 |
| PUT | `/api/v1/items/{id}` | 상품 이름·가격 수정 |
| PUT | `/api/v1/items/{id}/price` | 상품 가격만 수정 |
| DELETE | `/api/v1/items/{id}` | 상품 한 개 삭제 |
| DELETE | `/api/v1/items` | 전체 상품 삭제 |

상품 생성 요청 예시:

```json
{
  "name": "모니터",
  "price": 250000
}
```

## 응답 형식

정상 응답과 오류 응답 모두 같은 형식을 사용합니다.

```json
{
  "status": 200,
  "data": {
    "id": 1,
    "name": "노트북",
    "price": 1500000
  }
}
```

## 상태 코드

| 상태 코드 | 설명 |
|---|---|
| 200 | 조회, 수정, 삭제 성공 |
| 201 | 상품 생성 성공 |
| 400 | 잘못된 요청 값 또는 JSON 형식 |
| 404 | 상품을 찾을 수 없음 |
| 500 | 서버 내부 오류 테스트 |
| 503 | 서비스 사용 불가 테스트 |

5xx 응답 확인용 API:

```text
GET /api/v1/server-status/error
GET /api/v1/server-status/unavailable
```

## Middleware

`LoggingInterceptor`가 `/api/**` 요청의 시작과 완료 시점에 Method, URI, 응답 상태를 출력합니다.

```text
[LoggingInterceptor] 요청 시작: POST /api/v1/items
[LoggingInterceptor] 요청 완료: 201
```

## 주요 파일

| 파일 | 역할 |
|---|---|
| `ItemController.java` | CRUD API 8개 구현 |
| `ServerStatusController.java` | 500, 503 응답 확인 |
| `ItemController2.java` | Query Parameter 검색 예제 |
| `ItemController3.java` | HTTP Header 처리 예제 |
| `ItemDto.java` | 상품 데이터 구조 |
| `ItemCreateRequest.java` | 상품 생성 요청 데이터 |
| `ItemUpdateRequest.java` | 상품 수정 요청 데이터 |
| `ApiResponse.java` | `{status, data}` 응답 통일 |
| `LoggingInterceptor.java` | 요청 로그 Middleware |
| `WebConfig.java` | Interceptor 등록 |
| `GlobalExceptionHandler.java` | 공통 오류 응답 처리 |

## 실행 및 테스트

서버 실행:

```bash
./gradlew bootRun
```

테스트 실행:

```bash
./gradlew test
```

서버 기본 주소는 `http://localhost:8080`입니다.

데이터는 메모리에 저장되므로 서버를 다시 실행하면 초기화됩니다.
