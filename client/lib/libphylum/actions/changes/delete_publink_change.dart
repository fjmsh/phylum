import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/db/db.dart';

class DeletePublinkChange extends LocalChange<Publink> {
  @override
  final String objectId;

  @override
  String get description => 'Deleting';

  @override
  bool get persist => true;

  const DeletePublinkChange({required this.objectId});

  @override
  Publink? apply(Publink? data) {
    return null;
  }
}
