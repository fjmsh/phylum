import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/db/db.dart';

class UpdateResourcePermissionsChange extends LocalChange<Resource> {
  @override
  final String objectId;
  final int userId;
  final int permission;
  final DateTime timestamp;

  @override
  String get description => 'Updating Permissions';

  const UpdateResourcePermissionsChange({
    required this.objectId,
    required this.userId,
    required this.permission,
    required this.timestamp,
  });

  @override
  Resource? apply(Resource? data) {
    if (data == null) return null;
    var p = data.grants == null ? const <int, Map>{} : (jsonDecode(data.grants!) as Map).cast<int, Map>();
    if ((p[userId]?['p'] ?? 0) == permission) {
      return data;
    }
    if (permission == 0) {
      p.remove(userId);
    } else if (p.isEmpty) {
      // Empty means const map, so we can't add to it
      p = {
        userId: <String, int>{
          'p': permission,
          't': DateTime.now().millisecondsSinceEpoch,
        },
      };
    } else {
      p[userId] = <String, int>{
        'p': permission,
        't': DateTime.now().millisecondsSinceEpoch,
      };
    }
    final serialized = p.isEmpty ? null : json.encode(p);
    return data.copyWith(
      grants: Value(serialized),
      modified: Value(timestamp),
    );
  }
}
