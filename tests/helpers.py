import requests

def delete(api_url, api_key, path, permanent):
    return requests.post(f'{api_url}/fs/delete', headers={
        "Authorization": f'Bearer {api_key}'
    }, json={
        'path': path,
        'permanent': permanent,
    })

def mkdir(api_url, api_key, path):
    return requests.post(f'{api_url}/fs/mkdir', headers={
        "Authorization": f'Bearer {api_key}'
    }, json={
        'path': path,
    })

def upload_file(api_url, api_key, path, contents, conflict=0):
    return requests.put(f'{api_url}/fs/uploads/single', headers={
        "Authorization": f'Bearer {api_key}'
    }, data={
        'path': path,
        'conflict': conflict,
    }, files={
        'contents': ('upload', contents, 'application/octet-stream')
    })