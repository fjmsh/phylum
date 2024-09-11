import 'dart:async';

import 'package:drift/drift.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';

const resourceDetailsResponse = 'resourceDetails';
const resourceSummaryResponse = 'resourceSummary';

class PhylumDatastore with AccountListener<PhylumApiResponse, PhylumApiErrorResponse, PhylumAccount> {
  @override
  Future<void> initialize(PhylumAccount account) async {
    super.initialize(account);
    account.api.addResponseListener(processResponse);
  }

  Future<void> processResponse(Map<String, dynamic> data, dynamic tag) {
    final db = account.db;
    return db.transaction(() async => await _processResponse(data, tag, db));
  }

  FutureOr _processResponse(Map<String, dynamic> data, dynamic tag, AppDatabase db) {
    switch (tag) {
      case resourceDetailsResponse:
        return parseResourceDetails(data, db);
      case resourceSummaryResponse:
        return parseResourceSummary(data, db);
    }
  }

  Future parseResourceDetails(Map<String, dynamic> data, AppDatabase db) async {
    final details = parseResourceSummary(data['metadata'], db).copyWith(lastFetch: Value(DateTime.now()));
    final existing = Set.from(await db.managers.resources.filter((f) => f.parent.id.equals(data['metadata']['id'])).map((r) => r.id).get());
    final children = data.containsKey('children')
        ? (data['children'] as List).cast<Map>().map((c) {
            existing.remove(c['id']);
            return parseResourceSummary(c.cast<String, dynamic>(), db);
          })
        : <ResourcesCompanion>[];
    await db.resources.deleteWhere((o) => o.id.isIn(List.from(existing)));
    return db.batch((batch) {
      batch.insertAll(db.resources, [details, ...children], mode: InsertMode.insertOrReplace);
    });
  }

  ResourcesCompanion parseResourceSummary(Map<String, dynamic> data, AppDatabase db) {
    return ResourcesCompanion.insert(
      id: data['id'],
      parent: Value(data['parent']),
      name: data['name'],
      dir: data['dir'],
      modified: DateTime.parse(data['modified']),
      size: data['size'],
      etag: data['etag'],
      contentType: data['ctype'] ?? '',
    );
  }
}
