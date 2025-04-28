import 'package:flutter/material.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';

Future<void> downloadResource(BuildContext context, Resource r) => throw UnimplementedError();

class DownloadManager with ChangeNotifier {
  DownloadManager(PhylumAccount account) : super();

  Future<void> downloadResource(Resource r) async {}
}
