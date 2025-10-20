from app import main

class ListCursor:
    def execute(self, q): 
        pass
    def fetchall(self):
        return [{'id': 1, 'title': 'X', 'done': 0}]
    def __enter__(self): return self
    def __exit__(self, *a): pass

class ListConn:
    def cursor(self): return ListCursor()
    def __enter__(self): return self
    def __exit__(self, *a): pass

def test_tasks_list(monkeypatch):
    monkeypatch.setattr(main, 'get_conn', lambda: ListConn())

    client = main.app.test_client()
    rv = client.get('/tasks')

    assert rv.status_code == 200
    assert 'application/json' in rv.headers.get('Content-Type', '')

    data = rv.get_json()
    assert isinstance(data, dict)
    assert isinstance(data.get('items'), list)
    assert data['items'] == [{'id': 1, 'title': 'X', 'done': 0}]

