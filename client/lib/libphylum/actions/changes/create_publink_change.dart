import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/db/db.dart';

class CreatePublinkChange extends LocalChange<Publink> {
  @override
  final String objectId;
  final DateTime timestamp;
  final String root;
  final int accessLimit;
  final bool protected;
  final DateTime? expires;

  @override
  String get description => 'Creating';

  const CreatePublinkChange({
    required this.objectId,
    required this.timestamp,
    required this.root,
    required this.accessLimit,
    required this.protected,
    required this.expires,
  });

  @override
  Publink? apply(Publink? data) {
    return Publink(
      id: objectId,
      created: timestamp,
      root: root,
      accessLimit: accessLimit,
      accessed: 0,
      protected: protected,
      expires: expires,
    );
  }
}
