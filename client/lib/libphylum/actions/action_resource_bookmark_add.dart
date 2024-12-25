import 'dart:async';

import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/actions/action_resource_create.dart';
import 'package:phylum/libphylum/actions/action_resource_bookmark_remove.dart';
import 'package:phylum/libphylum/db/db.dart';
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

  final String bookmarkName;
  final int createdMillis;

  ResourceBookmarkAddAction._({
    required super.resourceId,
    required this.bookmarkName,
    required this.createdMillis,
  });

  ResourceBookmarkAddAction({
    required Resource r,
    String? name,
  }) : this._(
          resourceId: r.id,
          bookmarkName: name ?? r.name,
          createdMillis: DateTime.now().millisecondsSinceEpoch,
        );

  static ResourceBookmarkAddAction fromMap(Map<String, dynamic> map) {
    return ResourceBookmarkAddAction._(
      resourceId: map['resourceId'],
      bookmarkName: map['bookmarkName'],
      createdMillis: map['createdMillis'],
    );
  }

  @override
  String generateDescription() {
    return 'Adding Bookmarking: $bookmarkName';
  }

  @override
  Map<String, dynamic>? generateRequestBody() => null;

  @override
  Future<void> applyOptimisticUpdate() {
    return account.myListsRepository.insertOrReplaceBookmark(Bookmark(
      resourceId: resourceId,
      name: bookmarkName,
      created: createdMillis,
      deleted: false,
    ));
  }

  @override
  Future<void> revertOptimisticUpdate() {
    return account.myListsRepository.deleteBookmark(resourceId);
  }

  @override
  Map<String, dynamic> toMap() => {
        'resourceId': resourceId,
        'bookmarkName': bookmarkName,
        'createdMillis': createdMillis,
      };

  @override
  FutureOr<void> processResponse(ApiResponse response) async {
    if (response is PhylumApiSuccessResponse) {
      await account.myListsRepository.processSingleBookmarkResponse(response.data);
    }
  }

  @override
  bool dependsOn(PhylumAction action) =>
      action is ResourceAction &&
      (action is ResourceCreateAction || action is ResourceBookmarkAddAction || action is ResourceBookmarkRemoveAction) &&
      action.resourceId == resourceId;
}
