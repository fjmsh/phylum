import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/db/db.dart';

class CreateResourceChange extends LocalChange<Resource> {
  @override
  final String objectId;
  final String parent;
  final String localName;
  final DateTime timestamp;
  final int contentLength;
  final String contentType;
  final String contentSha256;

  @override
  bool get persist => false;

  @override
  String get description => 'Creating';

  const CreateResourceChange({
    required this.objectId,
    required this.parent,
    required this.localName,
    required this.timestamp,
    required this.contentLength,
    required this.contentType,
    required this.contentSha256,
  });

  @override
  Resource? apply(Resource? data) {
    if (data != null) {
      return data;
    }

    return Resource(
      id: objectId,
      parent: parent,
      name: localName,
      dir: true,
      created: timestamp,
      modified: timestamp,
      deleted: false,
      contentLength: contentLength,
      contentType: contentType,
      contentSha256: contentSha256,
    );
  }
}
