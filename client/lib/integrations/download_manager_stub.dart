import 'package:flutter/material.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';

Future<void> downloadResource(BuildContext context, Resource r, {ResourceVersion? version}) =>
    throw UnimplementedError();

class DownloadManager with ChangeNotifier {
  Future<void> downloadResource(PhylumAccount account, Resource r, {ResourceVersion? version}) async {}
}
