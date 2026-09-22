import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:phylum/util/clippy/clippy.dart';
import 'package:phylum/util/logging/logging.dart';
import 'package:phylum/util/upload/filesystem_io.dart';

const _platform = OptionalMethodChannel('cloud.phylum.drive/clippy');

ClippyInterface createInterface() => _ClippyNative();

class _ClippyNative extends ClippyInterface {
  @override
  void setPasteHandler(void Function(PasteData)? _) {}

  @override
  Future<PasteData?> read(BuildContext context) async {
    try {
      final result = await _platform.invokeMethod<List>('files');
      if (result == null) {
        return PasteError(
          error: 'Pasting from clipboard is not yet supported on this platform',
        );
      }
      if (result.isNotEmpty == true) {
        final paths = result.cast<String>();
        if (context.mounted) {
          final tree = await enumerateDirectories(context, paths);
          return PasteFilesData(tree: tree);
        }
      } else {
        final data = await Clipboard.getData('text/plain');
        final ids = Clippy.extractResourceIdsFromUrls(data?.text ?? '');

        if (ids.isNotEmpty) {
          return PasteResourcesData(ids: ids);
        }
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
