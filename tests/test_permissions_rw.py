import requests
import pytest 
from helpers import *

@pytest.fixture(scope='module')
def dir(api_url, admin_key, user):
    delete(api_url, admin_key, '/test/rw', True)
    resp = mkdir(api_url, admin_key, '/test/rw')
    assert resp.status_code == 200

    id = resp.json()['id']

    resp = resource_share(api_url, admin_key, f':{id}', user['id'], 36)
    assert resp.status_code == 200

    resp = upload_file(api_url, admin_key, f':{id}/file', f'contents of file')
    assert resp.status_code == 200

    yield id

    resp = delete(api_url, admin_key, f':{id}', True)
    assert resp.status_code == 200

def test_read(api_url, api_key, dir):
    resp = get_file_contents(api_url, api_key, f':{dir}/file', )
    assert resp.status_code == 200
    assert resp.content == b'contents of file'

def test_upload(api_url, api_key, dir):
    resp = upload_file(api_url, api_key, f':{dir}/upload', 'contents of upload')
    assert resp.status_code == 200

    resp = get_file_contents(api_url, api_key, f':{dir}/upload')
    assert resp.status_code == 200
    assert resp.content == b'contents of upload'

def test_delete(api_url, api_key, dir):
    resp = upload_file(api_url, api_key, f':{dir}/upload', 'contents of upload')
    assert resp.status_code == 200
    resp = delete(api_url, api_key, f':{dir}/upload', True)
    assert resp.status_code == 200

def test_share(api_url, api_key, user, dir):
    resp = resource_share(api_url, api_key, f':{dir}', user['id'], 36)
    assert resp.status_code == 403