part of 'parsers.dart';

class FullResource {
  final Resource resource;
  final Iterable<Publink> publinks;
  final Map<String, Permission> permissions;

  FullResource({required this.resource, required this.publinks, required this.permissions});
}

class PartialResource {
  final ResourcesCompanion resource;
  final Iterable<Publink>? publinks;

  PartialResource({required this.resource, required this.publinks});
}

FullResource parseFullResource(
  Map<String, dynamic> data, {
  required String username,
  required String? parent,
  Map<String, Permission>? inheritedPermissions,
}) {
  inheritedPermissions ??= (data['inherited_permissions'] as Map).cast<String, Permission>();
  final grants = (data['grants'] as Map)
      .cast<String, Map>()
      .map((k, v) => MapEntry(k, v.cast<String, dynamic>()['p'] as Permission));
  final permissions = Map.of(inheritedPermissions)..addAll(grants);

  final r = Resource(
    id: data['id'],
    parent: parent,
    name: data['name'],
    dir: data['dir'],
    created: DateTime.fromMillisecondsSinceEpoch(data['created']),
    modified: DateTime.fromMillisecondsSinceEpoch(data['modified']),
    deleted: data['deleted'] == 0 ? null : DateTime.fromMillisecondsSinceEpoch(data['deleted']),
    contentLength: data['c_len'],
    contentSha256: data['c_sha256'],
    contentType: data['c_type'],
    inheritedPermissions: jsonEncode(inheritedPermissions),
    grants: grants.isEmpty ? null : jsonEncode(grants),
    userPermission: permissions[username] ?? 0,
  );
  final publinks = parsePublinks(data['publinks'], r.id);
  return FullResource(resource: r, publinks: publinks, permissions: permissions);
}

ResourcesCompanion parseResourceAncestor(Map<String, dynamic> data) {
  return ResourcesCompanion(
    id: Value(data['id']),
    name: Value(data['name']),
    dir: Value(true),
    userPermission: Value(data['user_permission']),
  );
}

PartialResource parsePartialResource(Map<String, dynamic> data, [String? id]) {
  final r = ResourcesCompanion(
      id: Value(data['id'] ?? id),
      name: Value(data['name']),
      dir: Value(data['dir']),
      created: Value(DateTime.fromMillisecondsSinceEpoch(data['created'])),
      modified: Value(DateTime.fromMillisecondsSinceEpoch(data['modified'])),
      deleted: data['deleted'] == 0 ? Value(null) : Value(DateTime.fromMillisecondsSinceEpoch(data['deleted'])),
      contentLength: Value(data['c_len']),
      contentSha256: Value(data['c_sha256']),
      contentType: Value(data['c_type']),
      grants: data['grants'].isEmpty ? Value('') : Value(jsonEncode(data['grants'])));
  final publinks = data['publinks'] != null ? parsePublinks(data['publinks'], r.id.value) : null;
  return PartialResource(resource: r, publinks: publinks);
}
