import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/db/db.dart';

class CreateUserChange extends LocalChange<User> {
  @override
  String get objectId => localId.toString();
  final int localId;
  final String email;
  final String displayName;

  @override
  String get description => 'Creating';

  const CreateUserChange({
    required this.localId,
    required this.email,
    required this.displayName,
  });

  @override
  User? apply(User? data) {
    return User(id: localId, email: email, displayName: displayName);
  }
}
