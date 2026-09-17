part of 'responses.dart';

class BootstrapLoginResponse extends PhylumApiSuccessResponse {
  final String? apiToken;
  final AccountUser user;
  final ServerConfig config;
  final Iterable<Bookmark> bookmarks;
  final Iterable<User> users;
  final bool clear;
  final int until;

  BootstrapLoginResponse._({
    required this.apiToken,
    required this.user,
    required this.config,
    required this.bookmarks,
    required this.users,
    required this.until,
    required this.clear,
  });

  factory BootstrapLoginResponse.fromResponse(Map<String, dynamic> data) {
    final bookmarks = (data["bookmarks"] as List)
        .cast<Map>()
        .map((u) => parseBookmark(u.cast<String, dynamic>()))
        .toList(growable: false);
    final users = (data["users"] as List)
        .cast<Map>()
        .map((u) => parseUser(u.cast<String, dynamic>()))
        .toList(growable: false);

    return BootstrapLoginResponse._(
      apiToken: data['api_token'],
      user: AccountUser.fromMap(data['user'].cast<String, dynamic>()),
      config: ServerConfig.fromMap(data['config']),
      bookmarks: bookmarks,
      users: users,
      until: data['until'],
      clear: data['clear'],
    );
  }

  @override
  Future process(PhylumAccount account) async {
    final bookmarkIds = bookmarks.map((b) => b.resourceId);
    await account.db.batch((batch) {
      if (clear) {
        batch.deleteAll(account.db.bookmarks);
        batch.deleteAll(account.db.users);
      } else {
        batch.deleteWhere(
          account.db.bookmarks,
          (o) => o.resourceId.isNotIn(bookmarkIds),
        );
      }
      batch.insertAll(
        account.db.bookmarks,
        bookmarks,
        mode: InsertMode.insertOrReplace,
      );
      batch.insertAll(
        account.db.users,
        users,
        mode: InsertMode.insertOrReplace,
      );
    });

    account.user = user;
    account.bootstrapUntil = until;
    account.config = config;

    for (final b in bookmarks) {
      await account.datastore.get<Bookmark>().replaceRemoteData(
        b.resourceId,
        b,
      );
    }

    for (final u in users) {
      await account.datastore.get<User>().replaceRemoteData(u.id.toString(), u);
    }
  }
}
