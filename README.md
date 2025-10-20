# DevOps CRUD API

Небольшой учебный проект, собранный для практики DevOps-инструментов и базового CI/CD.
Flask-приложение разворачивается через Docker Compose вместе с Nginx и MySQL.

## О проекте
Простое REST-API для списка задач (CRUD) с health-check, метриками Prometheus и базой данных.
В проект встроен bash-скрипт `run.sh`, который автоматически поднимает весь стек и проводит smoke-тест (проверку всех CRUD-операций). Проект сопровождается CI/CD: GitHub Actions гоняет тесты на PR, а после merge в main автоматически деплоит обновление (образ в GHCR, self-hosted runner обновляет стек).

**Стек:** Python (Flask), MySQL, Nginx, Docker, Docker Compose, Prometheus, GitHub Actions (CI/CD), GHCR.

## Эндпоинты
- `GET /healthz` - проверка состояния приложения
- `GET /dbcheck` - проверка подключения к БД
- `GET /metrics` - метрики Prometheus
- `GET /tasks` - список задач
- `POST /tasks` - добавить новую задачу (`{"title": "..."}`)
- `PUT /tasks/<id>` - обновить задачу
- `DELETE /tasks/<id>` - удалить задачу

## Как запустить
```bash
git clone https://github.com/sunteo/devops_crud_api.git
cd devops_crud_api
./run.sh
```
По умолчанию API поднимается на порту 8080, а Prometheus — на 9090. Если эти порты заняты, можно указать другие при запуске:
```bash
PORT=8081 PROM_PORT=9091 ./run.sh
```

**Скрипт сам:**
- соберёт и поднимет контейнеры,
- дождётся готовности `/healthz` и успешного `/dbcheck`,
- если `.env` нет — создаст из `.env.sample` автоматически;
- выполнит тесты CRUD (create-read-update-delete),
- выведет результат в консоль.

## После запуска
API: `http://127.0.0.1:<PORT>` (по умолчанию - 8080)

Prometheus UI: `http://127.0.0.1:<PROM_PORT>` (по умолчанию - 9090)

**Примеры запросов:**

Проверка состояния приложения и доступность БД
```bash
curl -fsS http://127.0.0.1:$PORT/healthz
curl -fsS http://127.0.0.1:$PORT/dbcheck
```

CRUD
```bash
curl -fsS -X POST -H "Content-Type: application/json" \
  -d '{"title":"demo"}' http://127.0.0.1:$PORT/tasks

curl -fsS http://127.0.0.1:$PORT/tasks

curl -fsS -X PUT -H "Content-Type: application/json" \
  -d '{"done": true}' http://127.0.0.1:$PORT/tasks/1

curl -fsS -X DELETE http://127.0.0.1:$PORT/tasks/1
```

## Остановка
```bash
docker compose down -v
```

