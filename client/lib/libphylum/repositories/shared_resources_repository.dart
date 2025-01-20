import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/parsers/parsers.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';
import 'package:phylum/libphylum/repositories/resource_repository.dart';
import 'package:phylum/libphylum/requests/shared_resources_request.dart';

class SharedResourcesRepository {
  final PhylumAccount account;

  SharedResourcesRepository({required this.account});

  Future<ApiResult> refresh() async {
    return account.apiClient.sendRequest(
      SharedResourcesRequest(),
      (request, response) => parseJsonMapResponse(response, SharedResourcesResponse.fromResponse),
    );
  }
}

class SharedResourcesResponse extends PhylumApiSuccessResponse {
  final Iterable<ResourcesCompanion> resources;

  @override
  Iterable<(Type, String)> get updatedObjects => resources.map((u) => (Resource, u.id.value));

  @override
  Future<void> process(PhylumAccount account) async {
    final shared = resources.indexed.map((r) => SharedCompanion.insert(resourceId: r.$2.id.value, seq: r.$1));
    await account.db.batch((batch) {
      batch.insertAllOnConflictUpdate(account.db.resources, resources);
      batch.deleteAll(account.db.shared);
      batch.insertAll(account.db.shared, shared);
    });
  }

  SharedResourcesResponse({required this.resources});

  factory SharedResourcesResponse.fromResponse(Map<String, dynamic> data) {
    final resources =
        (data["shared"] as List).cast<Map>().map((u) => parsePartialResourceObject(u.cast<String, dynamic>()));
    return SharedResourcesResponse(resources: resources);
  }
}
