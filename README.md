# DevOps CRUD API

Небольшой учебный проект, собранный для практики DevOps-инструментов и базового CI/CD.
Flask-приложение разворачивается через Docker Compose вместе с Nginx и MySQL.

## О проекте
Простое REST-API для списка задач (CRUD) с health-check, метриками Prometheus и базой данных.
В проект встроен bash-скрипт `run.sh`, который автоматически поднимает весь стек и проводит smoke-тест (проверку всех CRUD-операций).

**Стек:** Python (Flask), MySQL, Nginx, Docker, Docker Compose, Prometheus.

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
git clone https://github.com/<username>/devops_crud_api.git
cd devops_crud_api
./run.sh
```
По умолчанию API поднимается на порту 8080. Если этот порт уже занят - можно указать другой при запуске:
```bash
PORT=1111 ./run.sh
```
**Скрипт сам:**
- соберёт и поднимет контейнеры,
- дождётся готовности /healthz,
- выполнит тесты CRUD (create-read-update-delete),
- выведет результат в консоль.

**После запуска**
API: `http://127.0.0.1:<PORT>` (по умолчанию - 8080)
При обращении к корневому эндпоинту / сервис возвращает статус работы в JSON-виде.

Prometheus UI: `http://127.0.0.1:9090`

## Остановка
```bash
docker compose down -v
```

