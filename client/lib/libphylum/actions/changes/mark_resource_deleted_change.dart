import 'package:drift/drift.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/db/db.dart';

class MarkResourceDeletedChange extends LocalChange<Resource> {
  @override
  final String objectId;
  final DateTime timestamp;

  @override
  String get description => 'Deleting';

  const MarkResourceDeletedChange({required this.objectId, required this.timestamp});

  @override
  Resource? apply(Resource? data) {
    return data?.copyWith(deleted: Value(timestamp));
  }
}
