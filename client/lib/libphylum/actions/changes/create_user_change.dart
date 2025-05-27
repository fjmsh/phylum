import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/db/db.dart';

class CreateUserChange extends LocalChange<User> {
  @override
  String get objectId => localId.toString();
  final int localId;
  final String email;
  final String name;

  @override
  String get description => 'Creating';

  const CreateUserChange({
    required this.localId,
    required this.email,
    required this.name,
  });

  @override
  User? apply(User? data) {
    return User(id: localId, email: email, name: name);
  }
}
