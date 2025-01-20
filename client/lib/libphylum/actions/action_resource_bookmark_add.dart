import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/actions/action_resource_create.dart';
import 'package:phylum/libphylum/actions/action_resource_bookmark_remove.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/parsers/parsers.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';

import 'action_resource.dart';

class ResourceBookmarkAddAction extends ResourceAction with JsonApiAction {
  static const kActionName = 'bookmarkAdd';
  @override
  String get actionName => kActionName;

  @override
  String get method => 'POST';

  @override
  String get endpoint => '/api/v1/my/bookmarks/add/$resourceId';

  @override
  Map<String, String> get queryParamters => {'name': bookmarkName};

  @override
  ResponseParser get parseResponse => (_, response) => parseJsonMapResponse(response, BookmarkResponse.fromResponse);

  @override
  List<LocalChange> get localChanges =>
      [AddBookmarkChange(resourceId, bookmarkName: bookmarkName, createdMillis: createdMillis)];

  @override
  String get description => 'Adding Bookmark: $bookmarkName';

  @override
  Map<String, dynamic> get props => {
        'resourceId': resourceId,
        'bookmarkName': bookmarkName,
        'createdMillis': createdMillis,
      };

  final String bookmarkName;
  final int createdMillis;

  ResourceBookmarkAddAction({
    required super.resourceId,
    required this.bookmarkName,
    required this.createdMillis,
  });

  factory ResourceBookmarkAddAction.fromMap(Map<String, dynamic> map) {
    return ResourceBookmarkAddAction(
      resourceId: map['resourceId'],
      bookmarkName: map['bookmarkName'],
      createdMillis: map['createdMillis'],
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

class AddBookmarkChange extends LocalChange<Bookmark> {
  @override
  final String objectId;
  final String bookmarkName;
  final int createdMillis;

  const AddBookmarkChange(
    this.objectId, {
    required this.bookmarkName,
    required this.createdMillis,
  });

  @override
  Bookmark? apply(Bookmark? data) {
    return Bookmark(
      resourceId: objectId,
      name: bookmarkName,
      created: createdMillis,
      deleted: false,
    );
  }
}
