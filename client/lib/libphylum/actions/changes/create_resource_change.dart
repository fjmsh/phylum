import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/util/permissions.dart';

class CreateResourceChange extends LocalChange<Resource> {
  @override
  final String objectId;
  final String parent;
  final String localName;
  final bool dir;
  final DateTime timestamp;
  final Permission userPermission;

  @override
  bool get persist => false;

  @override
  String get description => 'Creating';

  const CreateResourceChange({
    required this.objectId,
    required this.parent,
    required this.localName,
    required this.dir,
    required this.timestamp,
    required this.userPermission,
  });

  @override
  Resource? apply(Resource? data) {
    return Resource(
      id: objectId,
      parent: parent,
      name: localName,
      dir: dir,
      created: timestamp,
      modified: timestamp,
      userPermission: userPermission,
    );
  }
}
