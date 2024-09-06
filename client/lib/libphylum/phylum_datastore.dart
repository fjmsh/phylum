import 'package:drift/drift.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/db/db.dart';

const resourceDetailsResponse = 'resourceDetails';
const resourceSummaryResponse = 'resourceSummary';

class PhylumDatastore with AccountListener<Map<String, dynamic>> {
  late final AppDatabase db;

  @override
  Future<String?> initialize(Account<Map<String, dynamic>> account) async {
    super.initialize(account);
    db = AppDatabase(account.id);
    account.api.addResponseListener(processResponse);
    return null;
  }

  Future<void> processResponse(Map<String, dynamic>? data, dynamic tag) async {
    switch (tag) {
      case resourceDetailsResponse:
        parseResourceDetails(data!);
        break;
      case resourceSummaryResponse:
        parseResourceSummary(data!);
        break;
    }
  }

  Future parseResourceDetails(Map<String, dynamic> data) async {
    final details = parseResourceSummary(data['metadata']);
    final existing = Set.from(await db.managers.resources.filter((f) => f.parent.id.equals(data['metadata']['id'])).map((r) => r.id).get());
    final children = data.containsKey('children')
        ? (data['children'] as List).cast<Map>().map((c) {
            existing.remove(c['id']);
            return parseResourceSummary(c.cast<String, dynamic>());
          })
        : <ResourcesCompanion>[];
    await db.resources.deleteWhere((o) => o.id.isIn(List.from(existing)));
    return db.insertResources([details, ...children]);
  }

  ResourcesCompanion parseResourceSummary(Map<String, dynamic> data) {
    return ResourcesCompanion.insert(
      id: data['id'],
      parent: Value(data['parent']),
      name: data['name'],
      dir: data['dir'],
      modified: DateTime.parse(data['modified']),
      size: data['size'],
      etag: data['etag'],
    );
  }
}
