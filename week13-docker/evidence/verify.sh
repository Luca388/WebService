#!/usr/bin/env bash
# [학생 추가] evidence/*.txt가 실습 안내의 "관찰 기준"과 맞는지 검사합니다.
# collect.sh로 기록을 만든 뒤 실행합니다. 하나라도 어긋나면 종료 코드 1.
# 실행 (week13-docker 폴더에서): bash evidence/verify.sh
set -u
cd "$(dirname "$0")"
fail=0
V1='<h1>Release v1 is online.</h1>'
V2='<h1>Release v2 is online.</h1>'

check() { if [ "$2" = "$3" ]; then echo "PASS  $1"; else echo "FAIL  $1 (기대: $3 / 실제: $2)"; fail=1; fi; }
yes()   { if "$@" >/dev/null 2>&1; then echo y; else echo n; fi; }
has()   { yes grep -qF -- "$2" "$1"; }
nth_id(){ grep -E '^[0-9a-f]{64}$' "$1" | sed -n "${2}p"; }      # n번째 컨테이너 ID 출력 줄
n_ids() { grep -cE '^[0-9a-f]{64}$' "$1"; }
out()   { awk -v c="\$ $2" '$0==c{f=1;next} /^\$ /{f=0} f&&NF' "$1"; }  # 명령의 출력(빈 줄 제외)
web()   { grep -F -A1 -- "\$ curl $2" "$1" | tail -n1; }        # curl 요청의 결과 줄
same()  { if [ -n "$1" ] && [ "$1" = "$2" ]; then echo y; else echo n; fi; }
diff_() { if [ -n "$1" ] && [ -n "$2" ] && [ "$1" != "$2" ]; then echo y; else echo n; fi; }

f=00-setup.txt
check "00 Docker Client 표시"            "$(yes grep -q '^Client' $f)" y
check "00 Docker Server 표시"            "$(yes grep -q '^Server' $f)" y
check "00 시작 시 wsd13ko- 컨테이너 없음" "$(out $f 'docker ps -a --filter name=wsd13ko-' | wc -l | tr -d ' ')" 1

f=01-build-run.txt
check "01 wsd13ko:v1 빌드"           "$(has $f 'naming to docker.io/library/wsd13ko:v1')" y
check "01 18381에서 HTTP 200 + v1"   "$(web $f 'http://127.0.0.1:18381/')" "→ HTTP 200 · $V1"

f=02-logs-port.txt
check "02 로그에 GET /?visit=1"      "$(yes grep -qE '"GET /\?visit=1 HTTP/1.1" (200|304)' $f)" y
check "02 로그에 GET /?visit=2"      "$(yes grep -qE '"GET /\?visit=2 HTTP/1.1" (200|304)' $f)" y
check "02 docker port 출력"          "$(out $f 'docker port wsd13ko-a')" '80/tcp -> 127.0.0.1:18381'

f=03-stop-start.txt
check "03 중지 후 Exited"            "$(has $f 'Exited (0)')" y
check "03 중지 중 새 요청 실패"       "$(has $f '→ 응답 없음')" y
check "03 시작 후 다시 v1 응답"       "$(web $f 'http://127.0.0.1:18381/?step=3' )" "→ HTTP 200 · $V1"
check "03 ID 기록 2회"               "$(n_ids $f)" 2
check "03 중지 전·시작 후 ID 같음"     "$(same "$(nth_id $f 1)" "$(nth_id $f 2)")" y

f=04-isolation.txt
A=$(grep '^/wsd13ko-a ' $f); B=$(grep '^/wsd13ko-b ' $f)
check "04 A·B 컨테이너 ID 다름"       "$(diff_ "$(echo "$A" | cut -d' ' -f2)" "$(echo "$B" | cut -d' ' -f2)")" y
check "04 A·B 이미지 ID 같음"         "$(same  "$(echo "$A" | cut -d' ' -f3)" "$(echo "$B" | cut -d' ' -f3)")" y
check "04 A에서 파일 읽기"            "$(out $f 'docker exec wsd13ko-a cat /tmp/note.txt')" 'made-in-A'
check "04 B에서 파일 없음"            "$(out $f 'docker exec wsd13ko-b cat /tmp/note.txt' | head -n1)" "cat: can't open '/tmp/note.txt': No such file or directory"
check "04 A·B 마운트 없음"            "$(grep -c 'Mounts=\[\]$' $f)" 2

f=05-restart-recreate.txt   # ID 순서: 재시작 전, 재시작 후, run 출력, 재생성 후
check "05 ID 기록 4회"               "$(n_ids $f)" 4
check "05 재시작 전후 ID 같음"        "$(same  "$(nth_id $f 1)" "$(nth_id $f 2)")" y
check "05 재생성 후 ID 바뀜"          "$(diff_ "$(nth_id $f 2)" "$(nth_id $f 4)")" y
reads=$(grep -F -A1 '$ docker exec wsd13ko-a cat /tmp/note.txt' $f | grep -vE '^(\$|--)')
check "05 재시작 후 파일 유지"        "$(echo "$reads" | sed -n 1p)" 'made-in-A'
check "05 재생성 후 파일 없음"        "$(echo "$reads" | sed -n 2p)" "cat: can't open '/tmp/note.txt': No such file or directory"

f=06-v1-to-v2.txt
check "06 로컬 index.html이 v2"       "$(has $f "22:  $V2")" y
check "06 빌드 전 A는 v1"             "$(web $f 'http://127.0.0.1:18381/?step=6')" "→ HTTP 200 · $V1"
check "06 v2 빌드 후에도 18381은 v1"  "$(web $f 'http://127.0.0.1:18381/')" "→ HTTP 200 · $V1"
check "06 18383은 v2"                "$(web $f 'http://127.0.0.1:18383/')" "→ HTTP 200 · $V2"
check "06 v1·v2 이미지 ID 다름"       "$(diff_ "$(grep '^wsd13ko:v1 sha256' $f | cut -d' ' -f2)" "$(grep '^wsd13ko:v2 sha256' $f | cut -d' ' -f2)")" y

f=07-cleanup.txt
check "07 컨테이너 목록은 제목 줄만"   "$(out $f 'docker ps -a --filter name=wsd13ko-' | wc -l | tr -d ' ')" 1
check "07 wsd13ko 이미지 없음"        "$(out $f 'docker image ls wsd13ko' | grep -c '^wsd13ko:')" 0
check "07 기본 nginx 이미지는 남음"    "$(yes grep -q '^nginx:1.28-alpine' $f)" y

echo
if [ $fail -eq 0 ]; then echo "모든 관찰 기준 통과"; else echo "관찰 기준과 다른 결과가 있습니다"; fi
exit $fail
