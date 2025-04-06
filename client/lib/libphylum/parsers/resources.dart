part of 'parsers.dart';

Resource parseFullResource(Map<String, dynamic> data) {
  return Resource(
    id: data['id'],
    parent: data['parent'],
    name: data['name'],
    dir: data['dir'],
    created: DateTime.fromMillisecondsSinceEpoch(data['created']),
    modified: DateTime.fromMillisecondsSinceEpoch(data['modified']),
    deleted: data['deleted'] == 0 ? null : DateTime.fromMillisecondsSinceEpoch(data['deleted']),
    contentLength: data['c_len'],
    contentSha256: data['c_sha256'],
    contentType: data['c_type'],
    permissions: data['permissions'].isEmpty ? null : data['permissions'],
    publinks: data['publinks'].isEmpty ? null : data['publinks'],
    grants: data['grants'].isEmpty || data['grants'] == '{}' ? null : data['grants'],
  );
}

ResourcesCompanion parseResourceAncestor(Map<String, dynamic> data) {
  return ResourcesCompanion(
      id: Value(data['id']),
      parent: Value(data['parent']),
      name: Value(data['name']),
      dir: Value(true),
      permissions: data['permissions'].isEmpty ? Value(null) : Value(data['permissions']));
}

ResourcesCompanion parsePartialResource(Map<String, dynamic> data, [String? id]) {
  return ResourcesCompanion(
    id: Value(data['id'] ?? id),
    parent: Value.absentIfNull(data['parent']),
    name: Value.absentIfNull(data['name']),
    dir: Value.absentIfNull(data['dir']),
    created: data.containsKey('created') ? Value(DateTime.fromMillisecondsSinceEpoch(data['created'])) : Value.absent(),
    modified:
        data.containsKey('modified') ? Value(DateTime.fromMillisecondsSinceEpoch(data['modified'])) : Value.absent(),
    deleted: data.containsKey('deleted')
        ? data['deleted'] == 0
            ? Value(null)
            : Value(DateTime.fromMillisecondsSinceEpoch(data['deleted']))
        : Value.absent(),
    contentLength: Value.absentIfNull(data['c_len']),
    contentSha256: Value.absentIfNull(data['c_sha256']),
    contentType: Value.absentIfNull(data['c_type']),
    permissions: data.containsKey('permissions')
        ? data['permissions'].isEmpty
            ? Value(null)
            : Value(data['permissions'])
        : Value.absent(),
    grants: data.containsKey('grants')
        ? data['grants'].isEmpty || data['grants'] == '{}'
            ? Value(null)
            : Value(data['grants'])
        : Value.absent(),
    publinks: data.containsKey('publinks')
        ? data['publinks'].isEmpty
            ? Value(null)
            : Value(data['publinks'])
        : Value.absent(),
  );
}
