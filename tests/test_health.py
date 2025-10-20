from app.main import app

def test_health_endpoint():
    client = app.test_client()
    rv = client.get('/healthz')
    assert rv.status_code == 200
    assert rv.get_json().get('status') == 'healthy'
