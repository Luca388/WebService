# 웹서비스설계 한국어 분반 13주차 · Docker 이미지와 컨테이너 실습

작은 HTML 페이지를 Nginx 기반 Docker 이미지로 만들고, 이미지와 컨테이너의 차이·포트 연결·파일 격리·재시작과 재생성·v1→v2 변경을 확인한 실습입니다.

## 파일 구성

|파일|설명|
|---|---|
|[project/Dockerfile](project/Dockerfile)|`nginx:1.28-alpine` 위에 `index.html`을 복사하는 2줄짜리 Dockerfile (확장자 없음)|
|[project/.dockerignore](project/.dockerignore)|빌드 컨텍스트에 `Dockerfile`과 `index.html`만 보냄|
|[project/index.html](project/index.html)|Nginx가 제공하는 웹페이지 (현재 v2)|
|[evidence/](evidence/)|실습 00~07 명령과 실제 출력 기록, 수집 스크립트|

수업 배포 자료(실습 안내 HTML, 보고서 양식 docx 등)는 저장소에 포함하지 않았습니다.

## 실행 방법

준비: Docker Desktop 또는 Docker Engine(Linux 컨테이너)을 실행합니다. 첫 빌드에는 인터넷이 필요합니다.

```sh
git clone https://github.com/Luca388/WebService.git
cd WebService/week13-docker/project

docker version                      # Client와 Server가 모두 보여야 함
docker build -t wsd13ko:v2 .
docker run -d --name wsd13ko-v2 -p 127.0.0.1:18383:80 wsd13ko:v2
```

브라우저에서 <http://127.0.0.1:18383> 을 열면 `Release v2 is online.`이 보입니다.

`-p 127.0.0.1:18383:80`은 내 컴퓨터(호스트)의 18383번 포트를 컨테이너 안 Nginx의 80번 포트에 연결합니다. 포트가 사용 중이면 호스트 쪽 번호만 바꿉니다.

v1은 v1 커밋(`8deb683`)으로 이동해 빌드합니다.

```sh
git switch --detach 8deb683          # index.html이 v1 상태가 됨
docker build -t wsd13ko:v1 .
git switch main                      # 다시 v2로
docker run -d --name wsd13ko-a -p 127.0.0.1:18381:80 wsd13ko:v1
```

## v1 → v2 변경 내용

|구분|v1|v2|
|---|---|---|
|`index.html`의 `<h1>`|`Release v1 is online.`|`Release v2 is online.`|
|커밋|`8deb683` (배포된 시작 코드 그대로)|v2 커밋 (`git log -- project/index.html`)|
|이미지 태그 / 실습 때 이미지 ID|`wsd13ko:v1` / `c636e7dfaeb3`|`wsd13ko:v2` / `53a56304125a`|
|실습 컨테이너 / 주소|`wsd13ko-a` / <http://127.0.0.1:18381>|`wsd13ko-v2` / <http://127.0.0.1:18383>|

바뀐 것은 `<h1>` 문구 한 줄뿐입니다 (`git diff 8deb683 -- project/index.html`).

로컬 파일을 고치는 것만으로는 실행 중인 서비스가 바뀌지 않습니다. `COPY`는 빌드할 때 파일을 이미지에 한 번 복사할 뿐이라, 반영하려면 다음 순서를 거쳐야 합니다.

1. 로컬 `index.html` 수정·저장 → 이 시점에도 A(18381)는 계속 v1을 보여줌
2. `docker build -t wsd13ko:v2 .` → 새 이미지(새 이미지 ID) 생성
3. `docker run ... wsd13ko:v2` → 새 이미지로 새 컨테이너 실행 (기존 v1 컨테이너는 자동 교체되지 않음)

## 실습에서 사용한 이름과 포트

|구분|이름|호스트 포트 → 컨테이너 포트|
|---|---|---|
|이미지|`wsd13ko:v1`, `wsd13ko:v2`|–|
|컨테이너 A|`wsd13ko-a`|18381 → 80|
|컨테이너 B|`wsd13ko-b`|18382 → 80|
|v2 컨테이너|`wsd13ko-v2`|18383 → 80|

## 실습 기록 (evidence)

[evidence/collect.sh](evidence/collect.sh)가 실습 안내의 명령을 순서대로 실행하고 명령·출력을 저장합니다. 웹페이지 확인은 브라우저 대신 `curl`로 같은 주소를 요청해 상태 코드와 `<h1>` 문구를 기록했습니다. 보고서의 브라우저 화면은 따로 캡처했습니다.

|파일|확인한 내용|
|---|---|
|[00-setup.txt](evidence/00-setup.txt)|OS·CPU, Docker Client/Server 버전, 시작 파일|
|[01-build-run.txt](evidence/01-build-run.txt)|v1 빌드, 컨테이너 A 실행·ID, 18381에서 v1 응답|
|[02-logs-port.txt](evidence/02-logs-port.txt)|`?visit=1`·`?visit=2` 요청 로그(200), `docker port`|
|[03-stop-start.txt](evidence/03-stop-start.txt)|Up → Exited → Up, 중지 중 접속 실패, ID 유지|
|[04-isolation.txt](evidence/04-isolation.txt)|A·B 컨테이너 ID 다름 / 이미지 ID 같음, A에만 `/tmp/note.txt`, 마운트 없음|
|[05-restart-recreate.txt](evidence/05-restart-recreate.txt)|재시작: ID·파일 유지 / 삭제 후 재생성: 같은 이름, 새 ID, 파일 없음|
|[06-v1-to-v2.txt](evidence/06-v1-to-v2.txt)|파일만 고친 뒤 A는 v1, v2 빌드 후 18381=v1 / 18383=v2, 이미지 ID 비교|
|[07-cleanup.txt](evidence/07-cleanup.txt)|정리 후 `docker ps -a`·`docker image ls` 결과 (캡처 저장 후 실행), 기본 nginx 이미지와 로컬 파일은 남음|

```sh
cd week13-docker
bash evidence/collect.sh 0 1 2 3 4 5   # v1 실습
# project/index.html의 h1을 v2로 수정·저장
bash evidence/collect.sh 6             # v2 빌드·비교
bash evidence/collect.sh 7             # 캡처 저장 후 정리
```

## 정리

실습에서 만든 컨테이너 3개와 이미지 태그 2개만 지웁니다. 기본 `nginx:1.28-alpine` 이미지와 로컬 파일은 남습니다.

```sh
docker stop wsd13ko-a wsd13ko-b wsd13ko-v2
docker rm wsd13ko-a wsd13ko-b wsd13ko-v2
docker image rm wsd13ko:v1 wsd13ko:v2
```
