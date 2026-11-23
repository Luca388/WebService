#!/usr/bin/env bash
# [학생 추가] 보고서 3~6장 상세 증거 수집 스크립트
# - 별도 임시 DB(DB_PATH)와 별도 포트(3100), 임시 JWT_SECRET으로 서버를 띄웁니다.
#   data/app.sqlite와 data/jwt-secret.txt는 건드리지 않습니다.
# - 토큰은 출력하지 않습니다. 결과는 docs/evidence/*.txt로 저장됩니다.
# 실행: (starter 폴더에서) bash docs/evidence/collect.sh
set -euo pipefail
cd "$(dirname "$0")/../.."
OUT=docs/evidence
PORT=3100
BASE="http://127.0.0.1:$PORT"
TMP=$(mktemp -d)
DB="$TMP/evidence.sqlite"
SERVER_PID=""

stop_server() { if [ -n "$SERVER_PID" ]; then kill "$SERVER_PID" 2>/dev/null || true; wait "$SERVER_PID" 2>/dev/null || true; SERVER_PID=""; fi; }
trap 'stop_server; rm -rf "$TMP"' EXIT

fresh() {  # 서버 종료 → DB 삭제 → 새 DB로 서버 시작
  stop_server; rm -f "$DB" "$DB-wal" "$DB-shm"
  JWT_SECRET=$(openssl rand -hex 32) DB_PATH="$DB" PORT=$PORT node src/server.js >/dev/null 2>&1 &
  SERVER_PID=$!
  for _ in $(seq 50); do curl -sf "$BASE/api/health" >/dev/null && return; sleep 0.1; done
  echo "서버 시작 실패" >&2; exit 1
}

login() { local t; t=$(curl -s "$BASE/api/auth/login" -H 'Content-Type: application/json' \
  -d "{\"username\":\"$1\",\"password\":\"Classroom123!\"}" | jq -r .accessToken); printf -v "TOKEN_$1" '%s' "$t"; }
login_all() { for u in alice bob charlie manager1 manager2; do login "$u"; done; }

# call <행위자> <METHOD> <경로> [본문]  → 요청·응답 출력 (토큰은 [가림])
call() {
  local who=$1 method=$2 path=$3 body=${4:-}
  echo "▶ $method $path  (행위자: $who, Authorization: Bearer [가림])${body:+  본문: $body}"
  local res tvar="TOKEN_$who"
  res=$(curl -s -X "$method" "$BASE$path" -H "Authorization: Bearer ${!tvar}" \
    -H 'Content-Type: application/json' ${body:+-d "$body"} -w '\n%{http_code}')
  echo "◀ HTTP $(tail -n1 <<<"$res")  $(sed '$d' <<<"$res" | jq -c .)"
}
quiet() { call "$@" >/dev/null; }   # 준비 단계용(출력 생략)

sql() { sqlite3 -cmd '.timeout 5000' -header -column "$DB" "$1"; }
apps() { sql "SELECT a.id, u.username AS user, a.event_id AS event, a.status, a.created_at FROM applications a JOIN users u ON u.id=a.user_id ORDER BY a.id;"; }
hist() { sql "SELECT id, application_id AS app, actor_id AS actor, action, from_status AS from_s, to_status AS to_s, reason, cause_history_id AS cause FROM application_history ORDER BY id;"; }
snapshot() { echo "[$1] applications"; apps; echo; echo "[$1] application_history"; hist; echo; }
digest() { sqlite3 "$DB" "SELECT * FROM applications ORDER BY id; SELECT * FROM application_history ORDER BY id;" | shasum | cut -c1-12; }

# ───────────────── 3장 거부 사례 상세 ─────────────────
{
echo "# 3장 거부 사례 상세"
fresh; login_all
quiet alice POST /api/events/1/applications '{}'
echo "## 사례 A. 오래된 화면 승인 (T10, R8): alice가 대기 취소한 뒤 manager1이 예전 화면에서 승인"
call alice POST /api/applications/1/cancel '{}'
snapshot "요청 전"; B=$(digest)
call manager1 POST /api/applications/1/approve '{}'
echo; snapshot "요청 후"; A=$(digest)
echo "요청 전후 데이터 해시: $B → $A  ($( [ "$B" = "$A" ] && echo 동일 || echo 다름))"
echo
echo "## 사례 B. 비담당자 승인 (T09, R1): 행사 1(담당 manager1)의 신청을 manager2가 승인"
quiet bob POST /api/events/1/applications '{}'
B=$(digest)
call manager2 POST /api/applications/2/approve '{}'
call bob POST /api/applications/2/approve '{}'
echo; snapshot "요청 후"; A=$(digest)
echo "요청 전후 데이터 해시: $B → $A  ($( [ "$B" = "$A" ] && echo 동일 || echo 다름))"
} > "$OUT/03-rejection.txt"

# ───────────────── 4장 정원과 최신 상태 ─────────────────
{
echo "# 4장 정원과 최신 상태 (T13): 행사 2 정원 1명, 담당 manager2"
fresh; login_all
quiet bob POST /api/events/2/applications '{}'
quiet charlie POST /api/events/2/applications '{}'
echo "## 두 신청 모두 PENDING인 화면에서 manager2가 차례로 승인"
call manager2 POST /api/applications/1/approve '{}'
B=$(digest)
call manager2 POST /api/applications/2/approve '{}'
A=$(digest)
echo
echo "## 재조회"
echo "행사 2 승인 인원/정원: $(curl -s "$BASE/api/events" | jq -r '.[] | select(.id==2) | "\(.approvedCount)/\(.capacity)"')"
apps
echo "거부 요청 전후 데이터 해시: $B → $A  ($( [ "$B" = "$A" ] && echo 동일 || echo 다름))"
} > "$OUT/04-capacity.txt"

# ───────────────── 5장 대기 순서 ─────────────────
NEXT_SQL="SELECT a.id, u.username AS user, a.created_at FROM applications a JOIN users u ON u.id=a.user_id WHERE a.event_id=2 AND a.status='PENDING' ORDER BY a.created_at ASC, a.id ASC;"
{
echo "# 5장 대기 순서: 행사 2(정원 1), alice 승인 후 bob·charlie 대기 → alice 승인 취소"
for CASE in A B; do
  fresh; login_all
  quiet alice POST /api/events/2/applications '{}'
  quiet manager2 POST /api/applications/1/approve '{}'
  quiet bob POST /api/events/2/applications '{}'
  quiet charlie POST /api/events/2/applications '{}'
  if [ "$CASE" = A ]; then
    echo "## 경우 A. 등록 시각이 다름 (T18): charlie(id 3)의 created_at을 bob(id 2)보다 이르게 설정"
    sqlite3 "$DB" "UPDATE applications SET created_at='2026-11-20T09:00:00.000Z' WHERE id=3; UPDATE applications SET created_at='2026-11-20T10:00:00.000Z' WHERE id=2;"
  else
    echo "## 경우 B. 등록 시각이 같음 (T19): bob(id 2)·charlie(id 3)의 created_at을 같게 설정"
    sqlite3 "$DB" "UPDATE applications SET created_at='2026-11-20T09:00:00.000Z' WHERE id IN (2,3);"
  fi
  echo "[승인 취소 전] nextPending 정렬 결과 (created_at ASC, id ASC)"; sql "$NEXT_SQL"; echo
  call manager2 POST /api/applications/1/revoke '{"reason":"운영 사정으로 승인 취소"}'
  echo; echo "[승인 취소 후] applications"; apps; echo
  echo "[승인 취소 후] application_history"; hist; echo
done
} > "$OUT/05-queue-order.txt"

# ───────────────── 6장 롤백 증거 (T29) ─────────────────
{
echo "# 6장 롤백 증거 (T29): AUTO_APPROVE 이력 저장을 트리거로 실패시킴"
fresh; login_all
quiet alice POST /api/events/2/applications '{}'
quiet manager2 POST /api/applications/1/approve '{}'
quiet bob POST /api/events/2/applications '{}'
snapshot "요청 전"; B=$(digest)
TRIGGER="CREATE TRIGGER fail_auto BEFORE INSERT ON application_history WHEN NEW.action='AUTO_APPROVE' BEGIN SELECT RAISE(ABORT,'TEST_INJECTED_FAILURE'); END;"
echo "## 트리거 설치"; echo "$TRIGGER"; sqlite3 "$DB" "$TRIGGER"; echo
call manager2 POST /api/applications/1/revoke '{"reason":"운영 사정으로 승인 취소"}'
echo; snapshot "실패 요청 후"; A=$(digest)
echo "요청 전후 데이터 해시: $B → $A  ($( [ "$B" = "$A" ] && echo 동일 || echo 다름))"
echo
echo "## 트리거 제거 후 재시도"; sqlite3 "$DB" "DROP TRIGGER fail_auto;"; echo "DROP TRIGGER fail_auto;"
call manager2 POST /api/applications/1/revoke '{"reason":"운영 사정으로 승인 취소"}'
echo; snapshot "재시도 후"
} > "$OUT/06-rollback.txt"

echo "완료: $OUT/03-rejection.txt 04-capacity.txt 05-queue-order.txt 06-rollback.txt"
