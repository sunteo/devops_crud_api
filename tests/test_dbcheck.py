import types
from app import main

class DummyCursor:
    def execute(self, q): pass
    def fetchone(self): return {'ok': 1}
    def __enter__(self): return self
    def __exit__(self, *a): pass

class DummyConn:
    def cursor(self): return DummyCursor()
    def __enter__(self): return self
    def __exit__(self, *a): pass

def test_dbcheck_ok(monkeypatch):
    monkeypatch.setattr(main, 'get_conn', lambda: DummyConn())
    client = main.app.test_client()
    rv = client.get('/dbcheck')
    assert rv.status_code == 200
    assert rv.get_json()['db'] == 'ok'

def test_dbcheck_down(monkeypatch):
    class FailingConn:
        def __enter__(self): raise RuntimeError("boom")
        def __exit__(self, *a): pass
    monkeypatch.setattr(main, 'get_conn', lambda: FailingConn())
    client = main.app.test_client()
    rv = client.get('/dbcheck')
    assert rv.status_code == 200
    assert rv.get_json()['db'] == 'down'

