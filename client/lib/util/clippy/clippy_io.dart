import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:phylum/util/clippy/clippy.dart';
import 'package:phylum/util/logging/logging.dart';
import 'package:phylum/util/upload/filesystem_io.dart';

ClippyInterface createInterface() => _ClippyNative();

class _ClippyNative extends ClippyInterface {
  @override
  void setPasteHandler(void Function(PasteData)? _) {}

  @override
  Future<PasteData?> read(BuildContext context) async {
    try {
      final files = await Pasteboard.files();
      if (files.isNotEmpty) {
        if (context.mounted) {
          final tree = await enumerateDirectories(context, files);
          return PasteFilesData(tree: tree);
        }
      }
      final ids = Clippy.extractResourceIdsFromUrls(
        await Pasteboard.text ?? '',
      );

      if (ids.isNotEmpty) {
        return PasteResourcesData(ids: ids);
      }

      return null;
    } on PlatformException catch (e) {
      Log.warn('Failed to get files from clippy: ', e);
      rethrow;
    }
  }

  @override
  void write(List<Uri> resourceUrls) {
    Clipboard.setData(ClipboardData(text: resourceUrls.join('\n')));
  }
}
