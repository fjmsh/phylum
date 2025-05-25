import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:hive_ce/hive.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/requests/users_list_request.dart';
import 'package:phylum/libphylum/responses/responses.dart';

const _remoteUsersBoxName = 'remote_users';

class UserRepository extends Repository<PhylumAccount, User> {
  late final PhylumAccount _account;
  late final LazyBox<User?> _remoteDataBox;

  Map<int, User> _users = const {};
  Map<int, User> get users => _users;

  UserRepository();

  @override
  Future<Map<String, User?>> initializeAndRestoreRemoteData(PhylumAccount account) async {
    if (!Hive.isAdapterRegistered(const UserAdapter().typeId)) {
      Hive.registerAdapter(const UserAdapter());
    }

    final box = await account.openBox<User>(_remoteUsersBoxName);
    final remoteData = Map<String, User?>.fromIterable(box.keys, value: (key) => box.get(key));
    await box.close();
    _account = account;

    await account.db.users
        .select()
        .get()
        .then((users) => _users = Map.unmodifiable(Map<int, User>.fromIterable(users, key: (u) => u.id)));

    _remoteDataBox = await _account.openLazyBox(_remoteUsersBoxName);
    return remoteData;
  }

  Future<ApiResult> refresh() async {
    return _account.apiClient.sendRequest(
        UsersListRequest(), (request, response) => parseJsonMapResponse(response, UserListResponse.fromResponse),
        callback: (request, response) async {
      if (response is UserListResponse) {
        _users = Map.unmodifiable(Map<int, User>.fromIterable(response.users, key: (u) => u.id));
      }
    });
  }

  String getUserDisplayName(int userId) {
    final user = _users[userId];
    if (user == null) return 'Unknown User($userId)';
    return user.displayName.isNotEmpty ? user.displayName : user.email;
  }

  @override
  Future<void> persistRemoteData(Map<String, User?> remoteData) {
    return _remoteDataBox.putAll(remoteData);
  }

  @override
  Future<void> discardRemoteData(Iterable<String> objectIds) {
    return _remoteDataBox.deleteAll(objectIds);
  }

  @override
  Future<User?> load(String objectId) {
    return (_account.db.users.select()..where((o) => o.id.equals(int.parse(objectId)))).getSingleOrNull();
  }

  @override
  Future<void> save(String objectId, User data) {
    return _account.db.users.insertOne(data, mode: InsertMode.insertOrReplace);
  }

  @override
  Future<void> delete(String objectId) {
    return _account.db.users.deleteWhere((o) => o.id.equals(int.parse(objectId)));
  }
}

class UserAdapter implements TypeAdapter<User?> {
  const UserAdapter();

  @override
  int get typeId => 3;

  @override
  User? read(BinaryReader reader) {
    reader.readByte();
    final data = reader.readString();
    return data.isEmpty ? null : User.fromJson(json.decode(data));
  }

  @override
  void write(BinaryWriter writer, User? obj) {
    writer.writeByte(0); // Version marker, in case we need to change something in the future
    writer.writeString(obj?.toJsonString() ?? '');
  }
}
