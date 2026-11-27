# 웹서비스설계 한국어 분반 13주차 · Docker 이미지와 컨테이너 실습

작은 HTML 페이지를 Nginx 기반 Docker 이미지로 만들고, 이미지와 컨테이너의 차이·포트 연결·파일 격리·재시작과 재생성·v1→v2 변경을 확인한 실습입니다.

## 파일 구성

|파일|설명|
|---|---|
|[project/Dockerfile](project/Dockerfile)|`nginx:1.28-alpine` 위에 `index.html`을 복사하는 2줄짜리 Dockerfile (확장자 없음)|
|[project/.dockerignore](project/.dockerignore)|빌드 컨텍스트에 `Dockerfile`과 `index.html`만 보냄|
|[project/index.html](project/index.html)|Nginx가 제공하는 웹페이지|

수업 배포 자료(실습 안내 HTML, 보고서 양식 docx 등)는 저장소에 포함하지 않았습니다.

## 실행 방법

준비: Docker Desktop 또는 Docker Engine(Linux 컨테이너)을 실행합니다. 첫 빌드에는 인터넷이 필요합니다.

```sh
git clone https://github.com/Luca388/WebService.git
cd WebService/week13-docker/project

docker version                      # Client와 Server가 모두 보여야 함
docker build -t wsd13ko:v1 .
docker run -d --name wsd13ko-a -p 127.0.0.1:18381:80 wsd13ko:v1
```

브라우저에서 <http://127.0.0.1:18381> 을 엽니다.

`-p 127.0.0.1:18381:80`은 내 컴퓨터(호스트)의 18381번 포트를 컨테이너 안 Nginx의 80번 포트에 연결합니다. 18381이 사용 중이면 호스트 쪽 번호만 바꿉니다.

## 실습에서 사용한 이름과 포트

|구분|이름|호스트 포트 → 컨테이너 포트|
|---|---|---|
|이미지|`wsd13ko:v1`, `wsd13ko:v2`|–|
|컨테이너 A|`wsd13ko-a`|18381 → 80|
|컨테이너 B|`wsd13ko-b`|18382 → 80|
|v2 컨테이너|`wsd13ko-v2`|18383 → 80|

## 정리

실습에서 만든 컨테이너 3개와 이미지 태그 2개만 지웁니다. 기본 `nginx:1.28-alpine` 이미지와 로컬 파일은 남습니다.

```sh
docker stop wsd13ko-a wsd13ko-b wsd13ko-v2
docker rm wsd13ko-a wsd13ko-b wsd13ko-v2
docker image rm wsd13ko:v1 wsd13ko:v2
```
