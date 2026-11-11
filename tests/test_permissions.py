import requests
import pytest 
from helpers import *


def test_read_from_ro(api_url, api_key, dir_ro):
    resp = get_file_contents(api_url, api_key, f':{dir_ro}/file.0', )
    assert resp.status_code == 200
    assert resp.content == b'contents of file.0'

def test_write_to_ro(api_url, api_key, dir_ro):
    resp = upload_file(api_url, api_key, f':{dir_ro}/upload', 'this is a file upload test')
    assert resp.status_code == 403

def test_read_write_from_rw(api_url, api_key, dir_rw):
    resp = upload_file(api_url, api_key, f':{dir_rw}/upload', 'contents of upload')
    assert resp.status_code == 200

    resp = get_file_contents(api_url, api_key, f':{dir_rw}/upload')
    assert resp.status_code == 200
    assert resp.content == b'contents of upload'