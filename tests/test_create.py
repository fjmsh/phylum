import requests
import pytest 

def delete(api_url, user, path, permanent):
    return requests.post(f'{api_url}/fs/delete', headers={
        "Authorization": f'Bearer {user['api_key']}'
    }, json={
        'path': path,
        'permanent': permanent,
    })

def mkdir(api_url, user, path):
    return requests.post(f'{api_url}/fs/mkdir', headers={
        "Authorization": f'Bearer {user['api_key']}'
    }, json={
        'path': path,
    })

def upload_file(api_url, user, path, contents, conflict=0):
    return requests.put(f'{api_url}/fs/uploads/single', headers={
        "Authorization": f'Bearer {user['api_key']}'
    }, data={
        'path': path,
        'conflict': conflict,
    }, files={
        'contents': ('upload', contents, 'application/octet-stream')
    })

def test_mkdir(api_url, user):
    delete(api_url, user, '~/sandbox', True)
    resp = mkdir(api_url, user, '~/sandbox')
    assert resp.status_code == 200

    resp = mkdir(api_url, user, '~/sandbox/dir')
    assert resp.status_code == 200

def test_upload_file(api_url, user):
    delete(api_url, user, '~/sandbox', True)
    mkdir(api_url, user, '~/sandbox')

    resp = upload_file(api_url, user, '~/sandbox/upload', 'this is a file upload test')
    assert resp.status_code == 200
    resource = resp.json()
    assert len(resource['versions']) == 1
    version = resource['versions'][0]
    version_id = version['id']
    assert version['size'] == 26
    assert version['sha256'] == '6e5282a1d54d695a3cd411c6faee52f5cf8bb6fa37492b14d2e8175a37144d95'


def test_upload_duplicate(api_url, user):
    delete(api_url, user, '~/sandbox', True)
    mkdir(api_url, user, '~/sandbox')

    resp = upload_file(api_url, user, '~/sandbox/upload', 'this is a file upload test')
    assert resp.status_code == 200

    resp = upload_file(api_url, user, '~/sandbox/upload', 'this is a file upload test')
    assert resp.status_code == 200

    resource = resp.json()
    assert len(resource['versions']) == 1

def test_upload_reject(api_url, user):
    delete(api_url, user, '~/sandbox', True)
    mkdir(api_url, user, '~/sandbox')

    resp = upload_file(api_url, user, '~/sandbox/upload', 'this is a file upload test')
    assert resp.status_code == 200

    resp = upload_file(api_url, user, '~/sandbox/upload', 'this is a file upload test with other contents')
    assert resp.status_code == 412

def test_upload_rename(api_url, user):
    delete(api_url, user, '~/sandbox', True)
    mkdir(api_url, user, '~/sandbox')

    resp = upload_file(api_url, user, '~/sandbox/upload', 'this is a file upload test')
    assert resp.status_code == 200

    resp = upload_file(api_url, user, '~/sandbox/upload', 'this is a file upload test with other contents', 2)
    assert resp.status_code == 200

    resource = resp.json()
    assert len(resource['versions']) == 1
    version = resource['versions'][0]
    assert version['size'] == 46
    assert version['sha256'] == 'b9133511157e7d973b1e9ba69279a191619bb1d18cef6c668347c39c5cd8899d'

def test_upload_overwrite(api_url, user):
    delete(api_url, user, '~/sandbox', True)
    mkdir(api_url, user, '~/sandbox')

    resp = upload_file(api_url, user, '~/sandbox/upload', 'this is a file upload test')
    assert resp.status_code == 200

    resp = upload_file(api_url, user, '~/sandbox/upload', 'this is a file upload test with other contents', 3)
    assert resp.status_code == 200

    resource = resp.json()
    assert len(resource['versions']) == 2
    version = resource['versions'][0]
    assert version['size'] == 46
    assert version['sha256'] == 'b9133511157e7d973b1e9ba69279a191619bb1d18cef6c668347c39c5cd8899d'