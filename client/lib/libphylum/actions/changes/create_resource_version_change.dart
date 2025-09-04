import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/db/db.dart';

class CreateResourceVersionChange extends LocalChange<ResourceVersion> {
  @override
  final String objectId;
  final String resourceId;
  final DateTime created;
  final int size;
  final String mimeType;
  final String sha256;

  @override
  bool get persist => false;

  @override
  String get description => 'Creating Version';

  const CreateResourceVersionChange({
    required this.objectId,
    required this.resourceId,
    required this.created,
    required this.size,
    required this.mimeType,
    required this.sha256,
  });

  @override
  ResourceVersion? apply(ResourceVersion? data) {
    return ResourceVersion(
      id: objectId,
      resourceId: resourceId,
      created: created,
      deleted: false,
      size: size,
      mimeType: mimeType,
      sha256: sha256,
      imgres: 0,
    );
  }
}
