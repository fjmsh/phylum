import 'package:drift/drift.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/db/db.dart';

class MoveResourceChange extends LocalChange<Resource> {
  @override
  final String objectId;
  final String? parent;
  final String? name;
  final DateTime timestamp;

  @override
  String get description => 'Moving';

  const MoveResourceChange({
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
