import requests
import pytest 

def test_server_alive(api_url):
    response = requests.get(f'{api_url}/info')
    assert response.status_code == 200
    json = response.json()
    assert json['needs_config'] == False