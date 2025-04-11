import 'package:drift/drift.dart';
import 'package:hive/hive.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/requests/trash_list_request.dart';
import 'package:phylum/libphylum/responses/responses.dart';

const _remoteDataBoxName = 'remote_trashed_resources';

class TrashedResourceRepository extends Repository<PhylumAccount, TrashedResource> {
  late final PhylumAccount _account;
  late final LazyBox<String?> _remoteDataBox;

  TrashedResourceRepository();

  @override
  Future<Map<String, TrashedResource?>> initializeAndRestoreRemoteData(PhylumAccount account) async {
    final box = await account.openBox<Resource>(_remoteDataBoxName);
    final remoteData = Map<String, TrashedResource?>.fromIterable(box.keys, value: (key) => TrashedResource(id: key));
    await box.close();
    _account = account;
    _remoteDataBox = await account.openLazyBox(_remoteDataBoxName);
    return remoteData;
  }

  @override
  Future<void> persistRemoteData(Map<String, TrashedResource?> remoteData) {
    return _remoteDataBox.putAll(remoteData.map((k, v) => MapEntry(k, k)));
  }

  @override
  Future<void> discardRemoteData(Iterable<String> objectIds) {
    return _remoteDataBox.deleteAll(objectIds);
  }

  @override
  Future<TrashedResource?> load(String objectId) async {
    return (_account.db.trashedResources.select()..where((t) => t.id.equals(objectId))).getSingleOrNull();
  }

  @override
  Future<void> save(String objectId, TrashedResource data) {
    return _account.db.trashedResources.insertOne(data, mode: InsertMode.insertOrReplace);
  }

  @override
  Future<void> delete(String objectId) async {
    await _account.db.trashedResources.deleteWhere((t) => t.id.equals(objectId));
  }

  Future<ApiResult> refresh({String? cursor}) async {
    return _account.apiClient.sendRequest(
      TrashListRequest(cursor: cursor),
      (request, response) => parseJsonMapResponse(response, TrashListResponse.fromResponse),
    );
  }
}
