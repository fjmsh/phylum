import 'package:drift/drift.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/db/db.dart';

class PhylumDatastore with AccountListener<Map<String, dynamic>> {
  late final AppDatabase db;

  @override
  Future<void> initialize(Account<Map<String, dynamic>> account) async {
    super.initialize(account);
    db = AppDatabase(account.id);
    account.api.addResponseListener(processResponse);
  }

  Future<void> processResponse(Map<String, dynamic>? data, dynamic tag) async {
    switch (tag) {
      case "resourceDetails":
        parseResourceDetails(data!);
        break;
    }
  }

  Future parseResourceDetails(Map<String, dynamic> data) async {
    final details = parseResourceMetadata(data['metadata']);
    final children = (data['children'] as List).cast<Map>().map((c) => parseResourceMetadata(c.cast<String, dynamic>()));
    return db.insertResources([details, ...children]);
  }

  ResourcesCompanion parseResourceMetadata(Map<String, dynamic> data) {
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
