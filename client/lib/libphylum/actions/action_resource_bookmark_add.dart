import 'package:http/http.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/actions/action_resource_bookmark_remove.dart';
import 'package:phylum/libphylum/actions/action_resource_create.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';
import 'package:phylum/libphylum/responses/responses.dart';

import 'action_resource.dart';

class ResourceBookmarkAddAction extends ResourceAction with JsonApiAction {
  static const kActionName = 'bookmarkAdd';
  @override
  String get actionName => kActionName;

  @override
  String get method => 'POST';

  @override
  String get endpoint => '/api/v1/user/bookmarks/add';

  @override
  Map<String, dynamic>? get requestBody => {
        'path': '$resourceId:',
        'name': bookmarkName,
      };

  @override
  List<LocalChange> get localChanges =>
      [AddBookmarkChange(resourceId, bookmarkName: bookmarkName, dir: dir, createdMillis: createdMillis)];

  @override
  String get description => 'Adding Bookmark: $bookmarkName';

  @override
  Map<String, dynamic> get props => {
        'resourceId': resourceId,
        'bookmarkName': bookmarkName,
        'dir': dir,
        'createdMillis': createdMillis,
      };

  final String bookmarkName;
  final bool dir;
  final int createdMillis;

  ResourceBookmarkAddAction({
    required super.resourceId,
    required this.bookmarkName,
    required this.dir,
    required this.createdMillis,
  });

  factory ResourceBookmarkAddAction.fromMap(Map<String, dynamic> map) {
    return ResourceBookmarkAddAction(
      resourceId: map['resourceId'],
      bookmarkName: map['bookmarkName'],
      dir: map['dir'],
      createdMillis: map['createdMillis'],
    );
  }

  @override
  Future<ApiResponse<PhylumAccount>> parseResponse(StreamedResponse response) {
    return parseJsonMapResponse(response, BookmarkResponse.fromResponse);
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
  final bool dir;
  final int createdMillis;

  @override
  String get description => 'Adding Bookmark';

  const AddBookmarkChange(
    this.objectId, {
    required this.bookmarkName,
    required this.dir,
    required this.createdMillis,
  });

  @override
  Bookmark? apply(Bookmark? data) {
    return Bookmark(
      resourceId: objectId,
      name: bookmarkName,
      dir: dir,
      created: createdMillis,
      deleted: false,
    );
  }
}
