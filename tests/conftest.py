import pytest
import random
import requests
import string

from helpers import *

def pytest_addoption(parser):
    parser.addoption("--instance-url", action="store", default="", help="Phylum instance to run tests on")
    parser.addoption("--api-key", action="store", default="", help="API Key for connecting to instance")
    parser.addoption("--user-email", action="store", default="test@example.com", help="Unprivileged user to test api with")

@pytest.fixture(scope='session')
def api_url(request):
    instance_url = request.config.getoption("--instance-url")
    if instance_url == "":
        assert False

    return instance_url.rstrip("/") + "/api/v1"

@pytest.fixture(scope='session')
def admin_key(request):
    api_key = request.config.getoption("--api-key")
    if api_key == "":
        assert False

    return api_key

@pytest.fixture(scope='session')
def user_email(request):
    user_email = request.config.getoption("--user-email")
    if user_email == "":
        assert False

    return user_email

@pytest.fixture(scope='session')
def user(api_url, admin_key, user_email):
    headers = {
        "Authorization": f'Bearer {admin_key}'
    }
    response = requests.get(f'{api_url}/admin/users/list', headers=headers)
    assert response.status_code == 200
    users = [x for x in response.json()['users'] if x['email'] == user_email]
    if len(users) == 0:
        # Create users
        body = {
            'email': user_email,
            'name': 'API Test',
            'no_create_home': False,
            'no_send_email': True,
        }
        response = requests.post(f'{api_url}/admin/users/create', headers=headers, json=body)
        assert response.status_code == 200
        user = response.json()
    else:
        user = users[0]

    response = requests.post(f'{api_url}/admin/user/keys/generate', headers=headers, json={
        'user_id': user['id'],
    })
    assert response.status_code == 200

    key_id = response.json()['id']
    token = response.json()['token']
    u = {
        'id': user['id'],
        'email': user['email'],
        'home': user['home'],
        'api_key': token,
    }
    yield u

    response = requests.post(f'{api_url}/admin/user/keys/revoke', headers=headers, json={
        'user_id': user['id'],
        'id': key_id,
        'delete': True,
    })
    assert response.status_code == 200

@pytest.fixture(scope='session')
def api_key(user):
    return user['api_key']

@pytest.fixture(scope='session')
def dir_ro(api_url, admin_key, user):
    delete(api_url, admin_key, '/test/ro', True)
    resp = mkdir(api_url, admin_key, '/test/ro')
    assert resp.status_code == 200

    id = resp.json()['id']

    resp = resource_share(api_url, admin_key, f':{id}', user['id'], 4)
    assert resp.status_code == 200

    for i in range(10):
        resp = upload_file(api_url, admin_key, f':{id}/file.{i}', f'contents of file.{i}')
        assert resp.status_code == 200
    
    mkdir(api_url, admin_key, f':{id}/dir')
    mkdir(api_url, admin_key, f':{id}/dir/subdir')
    resp = upload_file(api_url, admin_key, f':{id}/dir/file', f'contents of dir/file')
    return id

@pytest.fixture(scope='session')
def dir_rw(api_url, admin_key, user):
    delete(api_url, admin_key, '/test/rw', True)
    resp = mkdir(api_url, admin_key, '/test/rw')
    assert resp.status_code == 200

    id = resp.json()['id']

    resp = resource_share(api_url, admin_key, f':{id}', user['id'], 36)
    assert resp.status_code == 200

    return id