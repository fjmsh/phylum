import 'package:drift/drift.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';
import 'package:phylum/libphylum/responses/responses.dart';

import 'action_resource.dart';
import 'action_resource_bookmark_add.dart';
import 'action_resource_create.dart';

class ResourceBookmarkRemoveAction extends ResourceAction with JsonApiAction {
  static const kActionName = 'bookmarkRemove';
  @override
  String get actionName => kActionName;

  @override
  String get method => 'POST';

  @override
  String get endpoint => '/api/v1/my/bookmarks/remove/$resourceId';

  @override
  ResponseParser get parseResponse => (_, response) => parseJsonMapResponse(response, BookmarkResponse.fromResponse);

  @override
  List<LocalChange> get localChanges => [RemoveBookmarkChange(resourceId)];

  @override
  String get description => 'Removing Bookmark: $bookmarkName';

  @override
  Map<String, dynamic> get props => {
        'resourceId': resourceId,
        'bookmarkName': bookmarkName,
      };

  final String bookmarkName;

  ResourceBookmarkRemoveAction({required super.resourceId, required this.bookmarkName});

  factory ResourceBookmarkRemoveAction.fromMap(Map<String, dynamic> map) {
    return ResourceBookmarkRemoveAction(
      resourceId: map['resourceId'],
      bookmarkName: map['bookmarkName'],
    );
  }

  @override
  bool dependsOn(PhylumAction action) =>
      action is ResourceAction &&
      (action is ResourceCreateAction ||
          action is ResourceBookmarkAddAction ||
          action is ResourceBookmarkRemoveAction) &&
      action.resourceId == resourceId;
}

class RemoveBookmarkChange extends LocalChange<Bookmark> {
  @override
  final String objectId;

  @override
  String get description => 'Removing Bookmark';

  const RemoveBookmarkChange(this.objectId);

  @override
  Bookmark? apply(Bookmark? data) {
    return data?.copyWithCompanion(BookmarksCompanion(deleted: Value(true)));
  }
}
