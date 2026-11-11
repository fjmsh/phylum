import requests
import pytest 
from helpers import *

@pytest.fixture(scope='session')
def dir(api_url, admin_key, user):
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
    yield id

    resp = delete(api_url, admin_key, f':{id}', True)
    assert resp.status_code == 200


def test_read(api_url, api_key, dir):
    resp = get_file_contents(api_url, api_key, f':{dir}/file.0', )
    assert resp.status_code == 200
    assert resp.content == b'contents of file.0'

def test_upload(api_url, api_key, dir):
    resp = upload_file(api_url, api_key, f':{dir}/upload', 'contents of upload')
    assert resp.status_code == 403

def test_delete(api_url, api_key, dir):
    resp = delete(api_url, api_key, f':{dir}/file.0', True)
    assert resp.status_code == 403

def test_share(api_url, api_key, user, dir):
    resp = resource_share(api_url, api_key, f':{dir}', user['id'], 36)
    assert resp.status_code == 403