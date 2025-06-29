part of 'responses.dart';

class BootstrapLoginResponse extends PhylumApiSuccessResponse {
  final String? apiKey;
  final AccountUser user;
  final Iterable<Bookmark> bookmarks;
  final Iterable<User> users;
  final bool clear;
  final int until;

  BootstrapLoginResponse._({
    required this.apiKey,
    required this.user,
    required this.bookmarks,
    required this.users,
    required this.until,
    required this.clear,
  });

  factory BootstrapLoginResponse.fromResponse(Map<String, dynamic> data) {
    final bookmarks = (data["bookmarks"] as List).cast<Map>().map((u) => parseBookmark(u.cast<String, dynamic>()));
    final users = (data["users"] as List).cast<Map>().map((u) => parseUser(u.cast<String, dynamic>()));
    return BootstrapLoginResponse._(
        apiKey: data['api_key'],
        user: parseAccountUser(data['user']),
        bookmarks: bookmarks,
        users: users,
        until: data['until'],
        clear: data['clear']);
  }

  @override
  Future process(PhylumAccount account) async {
    await account.db.batch((batch) {
      if (clear) {
        batch.deleteAll(account.db.bookmarks);
        batch.deleteAll(account.db.users);
      }
      batch.insertAll(account.db.bookmarks, bookmarks, mode: InsertMode.insertOrReplace);
      batch.insertAll(account.db.users, users, mode: InsertMode.insertOrReplace);
    });

    account.user = user;
    account.bootstrapUntil = until;

    for (final b in bookmarks) {
      await account.datastore.get<Bookmark>().replaceRemoteData(b.resourceId, b);
    }

    for (final u in users) {
      await account.datastore.get<User>().replaceRemoteData(u.id.toString(), u);
    }
  }
}
