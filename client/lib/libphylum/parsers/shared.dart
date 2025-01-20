import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/parsers/resources.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';

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
    final resources = (data["shared"] as List).cast<Map>().map((u) => parsePartialResource(u.cast<String, dynamic>()));
    return SharedResourcesResponse(resources: resources);
  }
}
