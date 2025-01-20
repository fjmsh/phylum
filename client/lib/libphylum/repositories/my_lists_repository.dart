import 'package:drift/drift.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';
import 'package:phylum/libphylum/repositories/resource_repository.dart';
import 'package:phylum/libphylum/requests/shared_resources_request.dart';

class MyListsRepository {
  final PhylumAccount account;

  MyListsRepository({required this.account});

  Stream<List<Resource>> watchRecents() {
    return account.db.selectRecents().watch();
  }

  Future<void> markResourceAccessed(String resourceId) {
    return account.db.recents.insertOnConflictUpdate(Recent(resourceId: resourceId, accessed: DateTime.now()));
  }

  Stream<List<Resource>> watchShared() {
    return account.db.selectShared().watch();
  }

  Future<ApiResult> refreshShared() async {
    return account.apiClient.sendRequest(SharedResourcesRequest(), callback: (request, response) async {
      if (response is PhylumApiSuccessResponse) {
        await processSharedResourcesResponse(response.data);
      }
    });
  }

  Future processSharedResourcesResponse(Map<String, dynamic> data) async {
    final db = account.db;
    final resources =
        (data["shared"] as List).cast<Map>().map((u) => parsePartialResourceObject(u.cast<String, dynamic>()));
    final shared = resources.indexed.map((r) => SharedCompanion.insert(resourceId: r.$2.id.value, seq: r.$1));
    await db.batch((batch) {
      batch.insertAllOnConflictUpdate(db.resources, resources);
      batch.deleteAll(db.shared);
      batch.insertAll(db.shared, shared);
    });
  }
}
