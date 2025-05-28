import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:hive_ce/hive.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/actions/action_user_invite.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/util/user_display_name.dart';

const _remoteUsersBoxName = 'remote_users';
const _keyLocalUserId = 'local_user_id';

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

    account.db.users
        .select()
        .watch()
        .listen((users) => _users = Map.unmodifiable(Map<int, User>.fromIterable(users, key: (u) => u.id)));

    _remoteDataBox = await _account.openLazyBox(_remoteUsersBoxName);
    return remoteData;
  }

  String getUserDisplayName(int userId) {
    return _users[userId]?.displayName ?? 'Unknown User($userId)';
  }

  Future<User> invite(String email, String name) async {
    final localId = _account.getPersisted<num>(_keyLocalUserId)?.toInt() ?? -1;
    await _account.persist(_keyLocalUserId, localId - 1);
    final user = User(id: localId, email: email, name: name);
    await _account.addAction(UserInviteAction(localId: localId, email: email, userName: name));
    return user;
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
