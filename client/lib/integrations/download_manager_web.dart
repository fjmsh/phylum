import 'package:flutter/material.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';

void downloadResource(BuildContext context, Resource r) {}

class DownloadManager with ChangeNotifier {
  DownloadManager(PhylumAccount account) : super();

  Future<void> downloadResource(Resource r) async {}
}
