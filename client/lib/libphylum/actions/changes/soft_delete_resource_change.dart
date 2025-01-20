import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/db/db.dart';

class SoftDeleteResourceChange extends LocalChange<Resource> {
  @override
  final String objectId;

  const SoftDeleteResourceChange({required this.objectId});

  @override
  Resource? apply(Resource? data) {
    return data?.copyWith(deleted: true);
  }
}
