part of 'parsers.dart';

Bookmark parseBookmark(Map<String, dynamic> data) {
  return Bookmark(
    resourceId: data['resource_id'],
    name: data['name'],
    dir: data['dir'],
    created: data['created'],
    deleted: data.containsKey('deleted') ? data['deleted'] : false,
  );
}
