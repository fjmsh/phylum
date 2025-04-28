import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:provider/provider.dart';

void downloadResource(BuildContext context, Resource r) {
  final apiClient = context.read<PhylumAccount>().apiClient;
  FileSaver().saveFile(
    name: basenameWithoutExtension(r.name),
    ext: extension(r.name),
    link: LinkDetails(
      link: apiClient.createUriBuilder('/api/v1/fs/contents/${r.id}').toString(),
      headers: apiClient.requestHeaders,
    ),
    mimeType: MimeType.custom,
    customMimeType: r.contentType,
  );
}

class DownloadManager with ChangeNotifier {
  DownloadManager(PhylumAccount account) : super();

  Future<void> downloadResource(Resource r) async {}
}
