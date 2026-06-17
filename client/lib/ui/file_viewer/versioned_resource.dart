import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/util/time.dart';

class VersionedResource {
  final Resource r;
  final ResourceVersion v;
  final bool showTimestamp;

  VersionedResource({
    required this.r,
    required this.v,
    required this.showTimestamp,
  });

  String get name => showTimestamp
      ? r.name
      : '${r.name} - ${v.created.formatNumericDateTime()}';
}
