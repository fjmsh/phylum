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

def get_file_contents(api_url, api_key, path):
    path = path.lstrip("/")
    return requests.get(f'{api_url}/fs/contents/{path}', headers={
        "Authorization": f'Bearer {api_key}'
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

def resource_share(api_url, api_key, path, user_id, permission):
    return requests.post(f'{api_url}/fs/share', headers={
        "Authorization": f'Bearer {api_key}'
    }, json={
        'path': path,
        'user_id': user_id,
        'permission': permission,
    })