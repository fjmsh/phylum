import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:phylum/util/clippy/clippy.dart';
import 'package:phylum/util/logging/logging.dart';
import 'package:phylum/util/upload/filesystem_io.dart';

const _platform = MethodChannel('cloud.phylum.drive/clippy');

ClippyInterface createInterface() => _ClippyNative();

class _ClippyNative extends ClippyInterface {
  @override
  void setPasteHandler(void Function(PasteData)? _) {}

  @override
  Future<PasteData?> read(BuildContext context) async {
    try {
      final result = await _platform.invokeMethod<List>('files');
      final paths = result?.cast<String>() ?? const [];
      if (context.mounted) {
        final tree = await enumerateDirectories(context, paths);
        return PasteFilesData(tree: tree);
      }
      return null;
    } on PlatformException catch (e) {
      Log.warn('Failed to get files from clippy: ', e);
      rethrow;
    }
  }

  @override
  void write(List<Uri> resourceUrls) {
    Clipboard.setData(ClipboardData(text: ''));
  }
}
