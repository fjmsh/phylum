import 'dart:async';
import 'dart:typed_data';

import 'package:phylum/libphylum/repositories/resource_repository.dart';
import 'package:phylum/util/clippy/clippy.dart';
import 'package:web/web.dart' as web;
import 'dart:js_interop';

ClippyInterface createInterface() => _ClippyWeb();

class _ClippyWeb extends ClippyInterface {
  void Function(PasteData)? _handler;

  _ClippyWeb() {
    web.document.addEventListener('paste', _handlePaste.toJS, true.toJS);
  }

  @override
  Future<PasteData?> read() async => throw UnimplementedError();

  @override
  void write(List<Uri> resourceUrls) {
    web.window.navigator.clipboard.writeText(resourceUrls.join('\n'));
  }

  @override
  void setPasteHandler(void Function(PasteData)? handler) {
    _handler = handler;
  }

  void _handlePaste(web.Event event) {
    event.preventDefault();
    final handler = _handler;
    if (handler == null) return;

    final pasteData = (event as web.ClipboardEvent).clipboardData
        ?.toPasteData();

    if (pasteData != null) {
      handler(pasteData);
    }
  }
}

extension on web.DataTransfer {
  PasteData? toPasteData() {
    for (int i = 0; i < this.files.length; i++) {
      final item = this.files.item(i);
      if (item == null) {
        return PasteError(error: 'Error reading pasted file');
      }
      if (item.type == '') {
        return PasteError(
          error: 'Cannot paste ${item.name}',
          details: 'Pasting folders is not supported on web clients',
        );
      }
    }
    final files = List.generate(this.files.length, (i) {
      final file = this.files.item(i)!;
      return UploadFile(
        path: file.name,
        size: file.size,
        stream: file.stream().toDartStream(),
      );
    });

    if (files.isNotEmpty) {
      return PasteFilesData(files: files);
    }

    final urls = getData(
      'text/plain',
    ).split('\n').map((str) => Uri.tryParse(str));

    if (urls.any((u) => u == null)) return null;

    urls.whereType<Uri>().toList(growable: false);
    // TODO: Extract resource ids from uris

    return null;
  }
}

extension ReadableStreamToDartStream on web.ReadableStream {
  Stream<Uint8List> toDartStream() {
    final controller = StreamController<Uint8List>();

    controller.onListen = () async {
      final reader = getReader() as web.ReadableStreamDefaultReader;

      try {
        while (true) {
          final result = await reader.read().toDart;
          if (result.done) {
            break;
          }
          final chunk = (result.value as JSUint8Array).toDart;
          controller.add(chunk);
        }
      } catch (e) {
        controller.addError(e);
      } finally {
        await controller.close();
      }
    };
    return controller.stream;
  }
}
