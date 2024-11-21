import 'dart:async';

import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/actions/bookmark_action.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';

class BookmarkAddAction extends PhylumAction with JsonApiAction, BookmarkAction {
  static const actionName = 'bookmarkAdd';
  @override
  String get name => actionName;

  @override
  String get method => 'POST';

  @override
  String get endpoint => '/api/v1/my/bookmarks/add/$resourceId?${Uri.encodeComponent(bookmarkName)}';

  @override
  final String resourceId;
  final String bookmarkName;
  final int createdMillis;

  BookmarkAddAction._({required this.resourceId, required this.bookmarkName, required this.createdMillis});

  BookmarkAddAction({
    required Resource r,
    String? name,
  }) : this._(
          resourceId: r.id,
          bookmarkName: name ?? r.name,
          createdMillis: DateTime.now().millisecondsSinceEpoch,
        );

  static BookmarkAddAction fromMap(Map<String, dynamic> map) {
    return BookmarkAddAction._(
      resourceId: map['resourceId'],
      bookmarkName: map['bookmarkName'],
      createdMillis: map['createdMillis'],
    );
  }

  @override
  String generateDescription(PhylumAccount account) {
    return 'Bookmarking $bookmarkName';
  }

  @override
  Map<String, dynamic>? generateRequestBody() => null;

  @override
  Future<void> initialize(PhylumAccount account) {
    return account.resourceRepository.trackServerData(resourceId);
  }

  @override
  Future<void> dispose(PhylumAccount account) {
    return account.resourceRepository.stopTrackingServerData(resourceId);
  }

  @override
  Future<void> applyOptimisticUpdate(PhylumAccount account) {
    return account.bookmarkRepository.create(Bookmark(
      resourceId: resourceId,
      name: name,
      created: createdMillis,
      deleted: false,
    ));
  }

  @override
  Future<void> revertOptimisticUpdate(PhylumAccount account) {
    return account.bookmarkRepository.delete(resourceId);
  }

  @override
  Map<String, dynamic> toMap() => {
        'resourceId': resourceId,
        'bookmarkName': bookmarkName,
        'createdMillis': createdMillis,
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
