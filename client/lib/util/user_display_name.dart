import 'package:phylum/libphylum/db/db.dart';

extension UserDisplayName on User {
  String get displayName => name.isEmpty ? email : name;
}
