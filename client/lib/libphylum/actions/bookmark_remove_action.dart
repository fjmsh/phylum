import 'dart:async';

import 'package:drift/drift.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/actions/bookmark_action.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';

class BookmarkRemoveAction extends PhylumAction with JsonApiAction, BookmarkAction {
  static const actionName = 'bookmarkRemove';
  @override
  String get name => actionName;

  @override
  String get method => 'POST';

  @override
  String get endpoint => '/api/v1/my/bookmarks/remove/$resourceId';

  @override
  final String resourceId;
  final String bookmarkName;

  BookmarkRemoveAction._({required this.resourceId, required this.bookmarkName});

  BookmarkRemoveAction({
    required Resource r,
  }) : this._(
          resourceId: r.id,
          bookmarkName: r.name,
        );

  static BookmarkRemoveAction fromMap(Map<String, dynamic> map) {
    return BookmarkRemoveAction._(
      resourceId: map['resourceId'],
      bookmarkName: map['bookmarkName'],
    );
  }

  @override
  String generateDescription(PhylumAccount account) {
    return 'Removing Bookmark: $bookmarkName';
  }

  @override
  Map<String, dynamic>? generateRequestBody() => null;

  @override
  Future<void> applyOptimisticUpdate(PhylumAccount account) {
    return account.bookmarkRepository.update(resourceId, BookmarksCompanion(deleted: Value(true)));
  }

  @override
  Future<void> revertOptimisticUpdate(PhylumAccount account) {
    return account.bookmarkRepository.update(resourceId, BookmarksCompanion(deleted: Value(false)));
  }

  @override
  Map<String, dynamic> toMap() => {
        'resourceId': resourceId,
        'bookmarkName': bookmarkName,
      };

  @override
  FutureOr<void> processResponse(PhylumAccount account, ApiResponse response) async {
    if (response is PhylumApiSuccessResponse) {
      await account.bookmarkRepository.processSingleBookmarkResponse(response.data);
    }
  }

  @override
  bool dependsOn(OfflineAction<PhylumAccount> action) => action is BookmarkAction && action.resourceId == resourceId;
}
