import requests

def delete(api_url, api_key, path, permanent):
    return requests.post(f'{api_url}/fs/delete', headers={
        "Authorization": f'Bearer {api_key}'
    }, json={
        'path': path,
        'permanent': permanent,
    })

def mkdir(api_url, api_key, path, conflict=0):
    return requests.post(f'{api_url}/fs/mkdir', headers={
        "Authorization": f'Bearer {api_key}'
    }, json={
        'path': path,
        'conflict': conflict,
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


def trash_list(api_url, api_key):
    return requests.get(f'{api_url}/trash/list', headers={
        "Authorization": f'Bearer {api_key}'
    })

def trash_restore(api_url, api_key, id, target='', name=''):
    return requests.post(f'{api_url}/trash/restore/{id}', headers={
        "Authorization": f'Bearer {api_key}'
    }, json={
        'target': target,
        'name': name,
    })