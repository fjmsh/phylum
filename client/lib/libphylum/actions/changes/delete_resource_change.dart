import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/db/db.dart';

class DeleteResourceChange extends LocalChange<Resource> {
  @override
  final String objectId;

  @override
  bool get persist => true;

  @override
  String get description => 'Deleting';

  const DeleteResourceChange({required this.objectId});

  @override
  Resource? apply(Resource? data) => null;
}
