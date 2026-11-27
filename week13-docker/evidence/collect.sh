#!/usr/bin/env bash
# [학생 추가] 13주차 Docker 실습 명령 실행 + 출력 기록 스크립트
# - 실습 안내(Week13_Docker_Lab_KO.html)의 명령을 같은 순서로 실행하고,
#   명령과 출력을 evidence/NN-*.txt에 저장합니다.
# - 브라우저 접속 대신 curl로 같은 주소를 요청해 상태 코드와 <h1> 문구를 기록합니다.
#   (보고서의 브라우저 캡처는 따로 찍습니다.)
# - 실습 6의 index.html 수정은 이 스크립트가 하지 않습니다. 직접 수정한 뒤 6을 실행합니다.
#
# 실행 (week13-docker 폴더에서):
#   bash evidence/collect.sh 0 1 2 3 4 5   # v1 실습
#   (project/index.html의 h1을 v2로 수정·저장)
#   bash evidence/collect.sh 6             # v2 빌드·비교
#   bash evidence/collect.sh 7             # 캡처를 모두 저장한 뒤 정리
set -uo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
OUT="$ROOT/evidence"
cd "$ROOT/project"

run()  { printf '\n$ %s\n' "$1"; eval "$1" 2>&1; local rc=$?; [ $rc -ne 0 ] && echo "(종료 코드 $rc)"; return 0; }
note() { printf '\n# %s\n' "$*"; }
web()  {  # web <URL> : 상태 코드와 h1 문구
  printf '\n$ curl %s\n' "$1"
  local body code
  body=$(curl -sS --max-time 5 -w '\n%{http_code}' "$1" 2>&1); code=$(tail -n1 <<<"$body")
  if [ "$code" = "000" ]; then sed '$d' <<<"$body"; echo "→ 응답 없음 (HTTP 요청 실패)"
  else echo "→ HTTP $code · $(sed '$d' <<<"$body" | grep -o '<h1>.*</h1>')"; fi
}
wait_web() { for _ in $(seq 50); do curl -s -o /dev/null "$1" && return; sleep 0.2; done; }
header() { echo "# $1"; echo "# 실행 시각: $(date '+%Y-%m-%d %H:%M:%S %Z') · 위치: week13-docker/project"; }
ps_table='docker ps -a --filter name=wsd13ko- --format "table {{.Names}}\t{{.ID}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"'

step0() { header "실습 00 · 준비"
  run 'uname -sm; sw_vers 2>/dev/null | head -2'
  run 'docker version'
  run 'ls -a'
  run 'docker ps -a --filter name=wsd13ko-'
}
step1() { header "실습 01 · 이미지 빌드와 컨테이너 A 실행"
  run 'cat Dockerfile'
  run 'docker pull nginx:1.28-alpine'
  run 'docker build -t wsd13ko:v1 .'
  run 'docker image ls wsd13ko'
  run 'docker run -d --name wsd13ko-a -p 127.0.0.1:18381:80 wsd13ko:v1'
  run 'docker ps --filter name=wsd13ko-'
  run 'docker inspect --format "{{.Id}}" wsd13ko-a'
  wait_web http://127.0.0.1:18381/
  web http://127.0.0.1:18381/
  note "이미지 안에 COPY된 파일 확인"
  run 'docker exec wsd13ko-a grep -o "<h1>.*</h1>" /usr/share/nginx/html/index.html'
}
step2() { header "실습 02 · 요청·로그·포트"
  note "각 주소를 요청한 뒤 한 번 더 요청(새로고침)"
  web 'http://127.0.0.1:18381/?visit=1'; web 'http://127.0.0.1:18381/?visit=1'
  web 'http://127.0.0.1:18381/?visit=2'; web 'http://127.0.0.1:18381/?visit=2'
  run 'docker logs --tail 30 wsd13ko-a'
  run 'docker port wsd13ko-a'
}
step3() { header "실습 03 · 중지와 시작"
  note "중지 전"
  run 'docker inspect --format "{{.Id}}" wsd13ko-a'
  run "$ps_table"
  run 'docker stop wsd13ko-a'
  note "중지 후"
  run 'docker ps -a --filter name=wsd13ko-'
  web 'http://127.0.0.1:18381/?step=3'
  run 'docker start wsd13ko-a'
  note "시작 후"
  run 'docker ps -a --filter name=wsd13ko-'
  run 'docker inspect --format "{{.Id}}" wsd13ko-a'
  wait_web http://127.0.0.1:18381/
  web 'http://127.0.0.1:18381/?step=3'
}
step4() { header "실습 04 · 같은 이미지로 만든 A와 B"
  run 'docker run -d --name wsd13ko-b -p 127.0.0.1:18382:80 wsd13ko:v1'
  run 'docker inspect --format "{{.Name}} {{.Id}} {{.Image}}" wsd13ko-a wsd13ko-b'
  run 'docker port wsd13ko-b'
  wait_web http://127.0.0.1:18382/
  web http://127.0.0.1:18381/; web http://127.0.0.1:18382/
  note "A 안에만 파일 만들기"
  run 'docker exec wsd13ko-a sh -c "echo made-in-A > /tmp/note.txt"'
  run 'docker exec wsd13ko-a cat /tmp/note.txt'
  run 'docker exec wsd13ko-b cat /tmp/note.txt'
  note "볼륨·바인드 마운트 연결 여부 (빈 목록 [] 이면 없음)"
  run 'docker inspect --format "{{.Name}} Mounts={{json .Mounts}}" wsd13ko-a wsd13ko-b'
}
step5() { header "실습 05 · 재시작과 재생성"
  note "5-2. 같은 컨테이너 재시작"
  run 'docker inspect --format "{{.Id}}" wsd13ko-a'
  run 'docker restart wsd13ko-a'
  run 'docker inspect --format "{{.Id}}" wsd13ko-a'
  run 'docker exec wsd13ko-a cat /tmp/note.txt'
  note "5-3. 삭제하고 같은 이름으로 새로 만들기"
  run 'docker stop wsd13ko-a'
  run 'docker rm wsd13ko-a'
  run 'docker run -d --name wsd13ko-a -p 127.0.0.1:18381:80 wsd13ko:v1'
  run 'docker inspect --format "{{.Id}}" wsd13ko-a'
  run 'docker exec wsd13ko-a cat /tmp/note.txt'
  note "B는 그대로 유지되는지"
  run "$ps_table"
  run 'docker exec wsd13ko-b cat /tmp/note.txt'
}
step6() { header "실습 06 · v1 → v2"
  note "6-1. 로컬 index.html 수정 확인"
  run 'grep -n "<h1>" index.html'
  note "다시 빌드하기 전 A의 웹페이지"
  web 'http://127.0.0.1:18381/?step=6'
  run 'docker exec wsd13ko-a grep -o "<h1>.*</h1>" /usr/share/nginx/html/index.html'
  note "6-2. 새 이미지 빌드 → 새 컨테이너 실행"
  run 'docker build -t wsd13ko:v2 .'
  run 'docker run -d --name wsd13ko-v2 -p 127.0.0.1:18383:80 wsd13ko:v2'
  run 'docker image ls wsd13ko'
  run 'docker ps --filter name=wsd13ko-'
  wait_web http://127.0.0.1:18383/
  note "v1(18381)과 v2(18383) 비교"
  web http://127.0.0.1:18381/; web http://127.0.0.1:18383/
  run 'docker inspect --format "{{.Name}} image={{.Image}} config={{.Config.Image}}" wsd13ko-a wsd13ko-b wsd13ko-v2'
  run 'docker image inspect --format "{{index .RepoTags 0}} {{.Id}}" wsd13ko:v1 wsd13ko:v2'
}
step7() { header "실습 07 · 실습 자원 정리"
  run 'docker stop wsd13ko-a wsd13ko-b wsd13ko-v2'
  run 'docker rm wsd13ko-a wsd13ko-b wsd13ko-v2'
  run 'docker image rm wsd13ko:v1 wsd13ko:v2'
  run 'docker ps -a --filter name=wsd13ko-'
  run 'docker image ls wsd13ko'
  note "남아 있는 기본 이미지와 로컬 파일"
  run 'docker image ls nginx'
  run 'ls -a'
}

names=([0]=00-setup [1]=01-build-run [2]=02-logs-port [3]=03-stop-start [4]=04-isolation [5]=05-restart-recreate [6]=06-v1-to-v2 [7]=07-cleanup)
[ $# -gt 0 ] || { echo "사용법: bash evidence/collect.sh <단계 0~7>..." >&2; exit 1; }
for s in "$@"; do
  f="$OUT/${names[$s]}.txt"
  "step$s" > "$f"
  echo "실습 0$s → evidence/$(basename "$f")"
done
