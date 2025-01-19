part of 'parsers.dart';

Bookmark parseBookmarkObject(Map<String, dynamic> data) {
  return Bookmark(
    resourceId: data['resource_id'],
    name: data['name'],
    created: data['created'],
    deleted: data['deleted'],
  );
}
