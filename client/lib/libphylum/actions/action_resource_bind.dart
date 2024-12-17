import 'package:phylum/libphylum/phylum_api_types.dart';

mixin ResourceBindAction on PhylumAction {
  String get parent;
  String get resourceName;
}
