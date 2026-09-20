import 'package:flutter/services.dart';
import 'package:phylum/util/clippy/clippy.dart';
import 'package:phylum/util/logging/logging.dart';

const _platform = MethodChannel('cloud.phylum.drive/clippy');

ClippyInterface createInterface() => _ClippyNative();

class _ClippyNative extends ClippyInterface {
  @override
  void setPasteHandler(void Function(PasteData)? _) {}

  @override
  Future<PasteData?> read() async {
    try {
      final result = await _platform.invokeMethod<List>('files');
      final paths = result?.cast<String>() ?? const [];
      // TODO: implement
      return null;
    } on PlatformException catch (e) {
      Log.warn('Failed to get files from clippy: ', e);
      rethrow;
    }
  }

  @override
  void write(List<Uri> resourceUrls) {
    // TODO: implement
  }
}
