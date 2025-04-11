import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/db/db.dart';

class UpdateResourceTrashedChange extends LocalChange<TrashedResource> {
  @override
  final String objectId;

  @override
  String get description => 'Updating Trashed';

  @override
  bool get persist => true;

  final bool add;

  const UpdateResourceTrashedChange({required this.objectId, required this.add});

  @override
  TrashedResource? apply(TrashedResource? data) {
    return add ? (data ?? TrashedResource(id: objectId)) : null;
  }
}
