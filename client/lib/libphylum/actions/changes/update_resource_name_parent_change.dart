import 'package:drift/drift.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/db/db.dart';

class UpdateResourceNameParentChange extends LocalChange<Resource> {
  @override
  final String objectId;
  final String? parent;
  final String? name;
  final DateTime timestamp;

  @override
  String get description => 'Updating name/parent';

  const UpdateResourceNameParentChange({
    required this.objectId,
    required this.parent,
    required this.name,
    required this.timestamp,
  });

  @override
  Resource? apply(Resource? data) {
    return data?.copyWith(
      parent: Value.absentIfNull(parent),
      name: name,
      modified: Value(timestamp),
    );
  }
}
