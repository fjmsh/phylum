import requests
import pytest 

@pytest.fixture()
def sandbox(api_url, user):
    response = requests.post(f'{api_url}/fs/delete', headers={
        "Authorization": f'Bearer {user['api_key']}'
    }, json={
        'path': '~/sandbox',
        'permanent': True,
    })

    response = requests.post(f'{api_url}/fs/mkdir', headers={
        "Authorization": f'Bearer {user['api_key']}'
    }, json={
        'path': '~/sandbox',
    })
    assert response.status_code == 200

    return response.json()['id']

def test_create_sandbox(sandbox, user):
    assert True