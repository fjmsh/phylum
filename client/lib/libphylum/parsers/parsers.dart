import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/account_user.dart';

Bookmark parseBookmark(Map<String, dynamic> data) {
  return Bookmark(
    resourceId: data['resource_id'],
    name: data['name'],
    dir: data['dir'],
    created: data['created'],
    deleted: data.containsKey('deleted') ? data['deleted'] : false,
  );
}

Iterable<Publink> parsePublinks(List data, String? root) {
  return data.cast<Map>().map((e) => parsePublink(e, root: root));
}

Iterable<ResourceVersion> parseResourceVersions(List data, String resourceId) {
  return data.cast<Map>().map((e) => parseResourceVersion(e, resourceId));
}

Publink parsePublink(Map data, {String? root}) {
  return Publink(
    id: data['id'],
    created: data['created'] == null ? null : DateTime.fromMillisecondsSinceEpoch(data['created'] * 1000),
    root: root ?? data['root'],
    accessLimit: data['access_limit'],
    protected: data['protected'],
    accessed: data['accessed'],
    expires: data['expires'] == null ? null : DateTime.fromMillisecondsSinceEpoch(data['expires'] * 1000),
  );
}

ResourceVersion parseResourceVersion(Map data, String resourceId) {
  return ResourceVersion(
    id: data['id'],
    created: DateTime.fromMillisecondsSinceEpoch(data['created'] * 1000),
    deleted: (data['deleted'] ?? 0) != 0,
    resourceId: resourceId,
    size: data['size'],
    mimeType: data['mime_type'],
    sha256: data['sha256'],
  );
}

User parseUser(Map data) {
  return User(
    id: data['id'],
    email: data['email'],
    name: data['name'],
  );
}

AccountUser parseAccountUser(Map data) {
  return AccountUser(
    id: data['id'],
    email: data['email'],
    name: data['name'],
    home: data['home'],
    permissions: data['permissions'],
  );
}
