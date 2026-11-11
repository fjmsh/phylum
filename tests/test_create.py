import requests
import pytest 
from helpers import *


def test_mkdir(api_url, api_key):
    delete(api_url, api_key, '~/sandbox', True)
    resp = mkdir(api_url, api_key, '~/sandbox')
    assert resp.status_code == 200

    resp = mkdir(api_url, api_key, '~/sandbox/dir')
    assert resp.status_code == 200

def test_upload_file(api_url, api_key):
    delete(api_url, api_key, '~/sandbox', True)
    mkdir(api_url, api_key, '~/sandbox')

    resp = upload_file(api_url, api_key, '~/sandbox/upload', 'this is a file upload test')
    assert resp.status_code == 200
    resource = resp.json()
    assert len(resource['versions']) == 1
    version = resource['versions'][0]
    version_id = version['id']
    assert version['size'] == 26
    assert version['sha256'] == '6e5282a1d54d695a3cd411c6faee52f5cf8bb6fa37492b14d2e8175a37144d95'


def test_upload_duplicate(api_url, api_key):
    delete(api_url, api_key, '~/sandbox', True)
    mkdir(api_url, api_key, '~/sandbox')

    resp = upload_file(api_url, api_key, '~/sandbox/upload', 'this is a file upload test')
    assert resp.status_code == 200

    resp = upload_file(api_url, api_key, '~/sandbox/upload', 'this is a file upload test')
    assert resp.status_code == 200

    resource = resp.json()
    assert len(resource['versions']) == 1

def test_upload_reject(api_url, api_key):
    delete(api_url, api_key, '~/sandbox', True)
    mkdir(api_url, api_key, '~/sandbox')

    resp = upload_file(api_url, api_key, '~/sandbox/upload', 'this is a file upload test')
    assert resp.status_code == 200

    resp = upload_file(api_url, api_key, '~/sandbox/upload', 'this is a file upload test with other contents')
    assert resp.status_code == 412

def test_upload_rename(api_url, api_key):
    delete(api_url, api_key, '~/sandbox', True)
    mkdir(api_url, api_key, '~/sandbox')

    resp = upload_file(api_url, api_key, '~/sandbox/upload', 'this is a file upload test')
    assert resp.status_code == 200

    resp = upload_file(api_url, api_key, '~/sandbox/upload', 'this is a file upload test with other contents', 2)
    assert resp.status_code == 200

    resource = resp.json()
    assert len(resource['versions']) == 1
    version = resource['versions'][0]
    assert version['size'] == 46
    assert version['sha256'] == 'b9133511157e7d973b1e9ba69279a191619bb1d18cef6c668347c39c5cd8899d'

def test_upload_overwrite(api_url, api_key):
    delete(api_url, api_key, '~/sandbox', True)
    mkdir(api_url, api_key, '~/sandbox')

    resp = upload_file(api_url, api_key, '~/sandbox/upload', 'this is a file upload test')
    assert resp.status_code == 200

    resp = upload_file(api_url, api_key, '~/sandbox/upload', 'this is a file upload test with other contents', 3)
    assert resp.status_code == 200

    resource = resp.json()
    assert len(resource['versions']) == 2
    version = resource['versions'][0]
    assert version['size'] == 46
    assert version['sha256'] == 'b9133511157e7d973b1e9ba69279a191619bb1d18cef6c668347c39c5cd8899d'