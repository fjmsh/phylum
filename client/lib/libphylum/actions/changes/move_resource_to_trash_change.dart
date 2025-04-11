import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/db/db.dart';

class MoveResourceToTrashChange extends LocalChange<TrashedResource> {
  @override
  final String objectId;

  @override
  String get description => 'Moving To Trash';

  @override
  bool get persist => true;

  const MoveResourceToTrashChange({required this.objectId});

  @override
  TrashedResource? apply(TrashedResource? data) {
    return data ?? TrashedResource(id: objectId);
  }
}
