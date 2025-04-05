part of 'parsers.dart';

Resource parseFullResource(Map<String, dynamic> data) {
  return Resource(
    id: data['id'],
    parent: data['parent'],
    name: data['name'],
    dir: data['dir'],
    created: DateTime.parse(data['created']),
    modified: DateTime.parse(data['modified']),
    deleted: data['deleted'] != null,
    contentLength: data['c_len'],
    contentSha256: data['c_sha256'],
    contentType: data['c_type'],
    permissions: data['permissions'].isEmpty ? null : data['permissions'],
    publinks: data['publinks'].isEmpty ? null : data['publinks'],
    grants: data['grants'].isEmpty ? null : data['grants'],
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
    created: Value.absentIfNull(data.containsKey('created') ? DateTime.parse(data['created']) : null),
    modified: Value.absentIfNull(data.containsKey('modified') ? DateTime.parse(data['modified']) : null),
    deleted: Value.absentIfNull(data.containsKey('deleted') ? data['deleted'] != null : null),
    contentLength: Value.absentIfNull(data['c_len']),
    contentSha256: Value.absentIfNull(data['c_sha256']),
    contentType: Value.absentIfNull(data['c_type']),
    permissions: data.containsKey('permissions')
        ? data['permissions'].isEmpty
            ? Value(null)
            : Value(data['permissions'])
        : Value.absent(),
    grants: data.containsKey('grants')
        ? data['grants'].isEmpty
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
