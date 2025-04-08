import 'package:drift/drift.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/db/db.dart';

class SoftDeleteResourceChange extends LocalChange<Resource> {
  @override
  final String objectId;

  @override
  String get description => 'Deleting';

  const SoftDeleteResourceChange({required this.objectId});

  @override
  Resource? apply(Resource? data) {
    return data?.copyWith(deleted: Value(DateTime.now()));
  }
}
