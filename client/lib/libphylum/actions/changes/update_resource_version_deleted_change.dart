import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/db/db.dart';

class UpdateResourceVersionDeletedChange extends LocalChange<ResourceVersion> {
  @override
  final String objectId;

  @override
  String get description => 'Deleting Version';

  const UpdateResourceVersionDeletedChange({required this.objectId});

  @override
  ResourceVersion? apply(ResourceVersion? data) {
    return null;
  }
}
