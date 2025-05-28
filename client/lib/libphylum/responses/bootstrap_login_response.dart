part of 'responses.dart';

class BootstrapLoginResponse extends PhylumApiSuccessResponse {
  final String? accessToken;
  final LoggedInUser user;
  final Iterable<Bookmark> bookmarks;
  final Iterable<User> users;
  final bool clear;
  final int until;

  BootstrapLoginResponse._({
    required this.accessToken,
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
        accessToken: data['access_token'],
        user: parseLoggedInUser(data['user']),
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
      batch.insertAll(account.db.bookmarks, bookmarks, mode: InsertMode.replace);
      batch.insertAll(account.db.users, users, mode: InsertMode.replace);
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
