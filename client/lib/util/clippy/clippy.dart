import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/db/resource_helpers.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/repositories/resource_repository.dart';

import 'clippy_stub.dart'
    if (dart.library.js_interop) 'clippy_web.dart'
    if (dart.library.ffi) 'clippy_io.dart';

class Clippy {
  static final ClippyInterface _instance = createInterface();

  static Future<PasteData?> read() => _instance.read();

  static void write(List<Uri> resourceUrls) => _instance.write(resourceUrls);

  static void setPasteHandler(void Function(PasteData)? listener) =>
      _instance.setPasteHandler(listener);
}

abstract class ClippyInterface {
  Future<PasteData?> read();

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
  final List<UploadFile> files;

  const PasteFilesData({required this.files});
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
