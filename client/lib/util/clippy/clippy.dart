import 'package:flutter/widgets.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/db/resource_helpers.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/util/upload/upload_utils.dart';

import 'clippy_stub.dart'
    if (dart.library.js_interop) 'clippy_web.dart'
    if (dart.library.ffi) 'clippy_io.dart';

class Clippy {
  static Uri _serverUri = Uri();

  static set serverUri(Uri val) {
    _serverUri = val;
  }

  static final ClippyInterface _instance = createInterface();

  static Future<PasteData?> read(BuildContext context) =>
      _instance.read(context);

  static void write(List<Uri> resourceUrls) => _instance.write(resourceUrls);

  static void setPasteHandler(void Function(PasteData)? listener) =>
      _instance.setPasteHandler(listener);

  static String? extractResourceId(Uri uri) {
    if (uri.isScheme(_serverUri.scheme) &&
        uri.authority == _serverUri.authority) {
      final segments = uri.pathSegments;
      if (segments.length == 2 &&
          (segments[0] == 'file' || segments[0] == 'folder')) {
        return segments[1];
      }
    }
    return null;
  }
}

abstract class ClippyInterface {
  Future<PasteData?> read(BuildContext context);

  void write(List<Uri> resourceUrls);

  void setPasteHandler(void Function(PasteData)? handler);
}

sealed class PasteData {
  const PasteData();
}

class PasteError extends PasteData {
  final String? error;
  final String? details;

  const PasteError({this.error, this.details});
}

class PasteFilesData extends PasteData {
  final DirTree tree;

  const PasteFilesData({required this.tree});
}

class PasteResourcesData extends PasteData {
  final List<String> ids;

  const PasteResourcesData({required this.ids});

  Future<Iterable<Resource>> getResources(PhylumAccount account) async =>
      account.db
          .getResources(ids)
          .then(
            (resources) =>
                resources.whereType<Resource>().toList(growable: false),
          );
}
