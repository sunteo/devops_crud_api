
import os
from flask import Flask, jsonify, request
from prometheus_flask_exporter import PrometheusMetrics
import pymysql

app = Flask(__name__)
metrics = PrometheusMetrics(app)
metrics.info('app_info', 'Application info', version='0.2.0')

DB_CFG = {
    "host": os.getenv("DB_HOST", "localhost"),
    "user": os.getenv("DB_USER", "root"),
    "password": os.getenv("DB_PASSWORD", ""),
    "database": os.getenv("DB_NAME", ""),
    "cursorclass": pymysql.cursors.DictCursor,
    "charset": "utf8mb4",
    "autocommit": True,
}

def get_conn():
    return pymysql.connect(**DB_CFG)

@app.route("/")
def index():
    return jsonify(status="ok", message="Hello from DevOps pet project")

@app.route("/healthz")
def healthz():
    return jsonify(status="healthy"), 200

@app.route("/dbcheck")
def dbcheck():
    try:
        with get_conn() as conn, conn.cursor() as cur:
            cur.execute("SELECT 1 AS ok")
            row = cur.fetchone()
        return jsonify(db="ok", result=row), 200
    except Exception as e:
        return jsonify(db="down", error=str(e)), 200

@app.route("/tasks")
def tasks():
    try:
        with get_conn() as conn, conn.cursor() as cur:
            cur.execute("SELECT id, title, done FROM tasks ORDER BY id")
            rows = cur.fetchall()
        return jsonify(items=rows), 200
    except Exception as e:
        return jsonify(error=str(e)), 500

@app.route("/tasks/<int:task_id>", methods=["PUT"])
def update_task(task_id):
    try:
        payload = request.get_json(force=True)
        done = bool((payload or {}).get("done", False))

        with get_conn() as conn, conn.cursor() as cur:
            cur.execute("UPDATE tasks SET done=%s WHERE id=%s", (done, task_id))
            if cur.rowcount == 0:
                return jsonify(error="task not found"), 404

        return jsonify(id=task_id, done=done), 200
    except Exception as e:
        return jsonify(error=str(e)), 500


@app.route("/tasks/<int:task_id>", methods=["DELETE"])
def delete_task(task_id):
    try:
        with get_conn() as conn, conn.cursor() as cur:
            cur.execute("DELETE FROM tasks WHERE id=%s", (task_id,))
            if cur.rowcount == 0:
                return jsonify(error="task not found"), 404

        return jsonify(status="deleted", id=task_id), 200
    except Exception as e:
        return jsonify(error=str(e)), 500

@app.route("/tasks", methods=["POST"])
def add_task():
    try:
        payload = request.get_json(force=True)
        
        title = (payload or {}).get("title", "").strip()
        
        if not title:
            return jsonify(error="title is required"), 400

        with get_conn() as conn, conn.cursor() as cur:
            cur.execute("INSERT INTO tasks (title, done) VALUES (%s, %s)", (title, False))
            
            cur.execute("SELECT LAST_INSERT_ID() AS id")
            new_id = cur.fetchone()["id"]

        return jsonify(id=new_id, title=title, done=False), 201

    except Exception as e:
        return jsonify(error=str(e)), 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
