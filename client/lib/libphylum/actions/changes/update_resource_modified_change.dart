import 'package:drift/drift.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/db/db.dart';

class UpdateResourceModifiedChange extends LocalChange<Resource> {
  @override
  final String objectId;
  final DateTime timestamp;

  @override
  String get description => 'Updating Modified';

  const UpdateResourceModifiedChange({
    required this.objectId,
    required this.timestamp,
  });

  @override
  Resource? apply(Resource? data) {
    return data?.copyWith(modified: Value(timestamp));
  }
}
