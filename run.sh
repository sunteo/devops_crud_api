#!/usr/bin/env bash
set -euo pipefail

PORT="${PORT:-8080}"
BASE_URL="http://127.0.0.1:${PORT}"
HEALTH_URL="${BASE_URL}/healthz"
DBCHECK_URL="${BASE_URL}/dbcheck"
TASKS_URL="${BASE_URL}/tasks"

line(){ printf '%*s\n' "${COLUMNS:-80}" '' | tr ' ' '-'; }
title(){ line; echo "$1"; line; }
ok(){ echo "✅ $*"; }
fail(){ echo "❌ $*" >&2; exit 1; }

print_tasks_table() {
  if docker run --rm ghcr.io/jqlang/jq:latest -V >/dev/null 2>&1 </dev/null; then
    if command -v column >/dev/null 2>&1; then
      docker run --rm -i ghcr.io/jqlang/jq:latest -r '
        .items
        | (["ID","DONE","TITLE"]),
          (.[] | [(.id|tostring),
                   (if (.done==true or .done==1) then "x" else " " end),
                   .title])
        | @tsv
      ' | column -t -s $'\t'
    else
      docker run --rm -i ghcr.io/jqlang/jq:latest -r '
        .items
        | (["ID","DONE","TITLE"]),
          (.[] | [(.id|tostring),
                   (if (.done==true or .done==1) then "x" else " " end),
                   .title])
        | @tsv
      '
    fi
  else
    cat
  fi
}

title "DevOps CRUD API: up + smoke test"
command -v docker >/dev/null 2>&1 || fail "Docker not found"
docker compose version >/dev/null 2>&1 || fail "'docker compose' plugin not available"

if [[ ! -f .env && -f .env.sample ]]; then
  echo ".env not found — copying .env.sample → .env"
  cp .env.sample .env
fi

title "Compose: build & up"
docker compose up -d --build
ok "Containers started"

title "Readiness: /healthz"
echo -n "Waiting ${HEALTH_URL} "
for i in {1..90}; do
  if curl -fsS "${HEALTH_URL}" >/dev/null 2>&1; then
    echo "OK"; ok "App is responding at ${BASE_URL}"; break
  fi
  echo -n "."
  sleep 1
  [[ $i -eq 90 ]] && { echo; fail "Timeout waiting /healthz"; }
done

title "Readiness DB /dbcheck"
echo -n "Waiting ${DBCHECK_URL} (db=ok) "
for i in {1..90}; do
  RESP="$(curl -fsS "${DBCHECK_URL}" || true)"
  if echo "$RESP" | grep -q '"db":"ok"'; then
    echo "OK"; ok "Database ready"; break
  fi
  echo -n "."
  sleep 1
  [[ $i -eq 90 ]] && { echo; fail "Timeout waiting db=ok on /dbcheck"; }
done

title "CRUD smoke test"
TITLE="CI smoke $(date +%s)"
echo "→ POST /tasks  title='${TITLE}'"
CREATE_RESP="$(curl -fsS -X POST -H "Content-Type: application/json" \
  -d "{\"title\":\"${TITLE}\"}" \
  "${TASKS_URL}")"
echo "resp: ${CREATE_RESP}"

TASK_ID="$(echo "${CREATE_RESP}" | sed -nE 's/.*"id"[[:space:]]*:[[:space:]]*([0-9]+).*/\1/p')"
[[ -n "${TASK_ID}" && "${TASK_ID}" =~ ^[0-9]+$ ]] || fail "Cannot extract id from response"
ok "Created task id=${TASK_ID}"

echo "→ GET /tasks  (should contain '${TITLE}')"
LIST1="$(curl -fsS "${TASKS_URL}")"
echo "Table:"; echo "${LIST1}" | print_tasks_table
echo "${LIST1}" | grep -q "${TITLE}" || fail "Created task not found in list"
ok "Task present in list"

echo "→ PUT /tasks/${TASK_ID}  done=true"
UPDATE_RESP="$(curl -fsS -X PUT -H "Content-Type: application/json" \
  -d '{"done": true}' \
  "${TASKS_URL}/${TASK_ID}")"
echo "resp: ${UPDATE_RESP}"

echo "→ GET /tasks  (expect done=true/1 for id=${TASK_ID})"
LIST2="$(curl -fsS "${TASKS_URL}")"
echo "Table:"; echo "${LIST2}" | print_tasks_table
if echo "${LIST2}" | grep -Eq "\"id\":${TASK_ID}[^}]*\"done\":(true|1)|\"done\":(true|1)[^}]*\"id\":${TASK_ID}"; then
  ok "Status updated"
else
  fail "Status not updated for id=${TASK_ID}"
fi

echo "→ DELETE /tasks/${TASK_ID}"
DEL_RESP="$(curl -fsS -X DELETE "${TASKS_URL}/${TASK_ID}")"
echo "resp: ${DEL_RESP}"
ok "Deleted id=${TASK_ID}"

echo "→ GET /tasks  (ensure '${TITLE}' is gone)"
LIST3="$(curl -fsS "${TASKS_URL}")"
echo "Table:"; echo "${LIST3}" | print_tasks_table
if echo "${LIST3}" | grep -q "${TITLE}"; then
  fail "Record still present after delete"
fi

title "Result"
ok "CRUD smoke test passed"
ok "Open: ${BASE_URL}"

