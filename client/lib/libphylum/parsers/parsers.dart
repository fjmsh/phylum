import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/logged_in_user.dart';

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

Publink parsePublink(Map data, {String? root}) {
  return Publink(
    id: data['id'],
    created: data['created'] == null ? null : DateTime.fromMillisecondsSinceEpoch(data['created']),
    root: root ?? data['root'],
    accessLimit: data['access_limit'],
    protected: data['protected'],
    accessed: data['accessed'],
    expires: data['expires'] == null ? null : DateTime.fromMillisecondsSinceEpoch(data['expires']),
  );
}

User parseUser(Map data) {
  return User(
    id: data['id'],
    email: data['email'],
    name: data['name'],
  );
}

LoggedInUser parseLoggedInUser(Map data) {
  return LoggedInUser(
    id: data['id'],
    email: data['email'],
    name: data['name'],
    home: data['home'],
    permissions: data['permissions'],
  );
}
