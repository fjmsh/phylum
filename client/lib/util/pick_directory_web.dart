import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

bool get folderUploadSupported => true;

@JS()
external JSPromise<web.FileSystemDirectoryHandle> showDirectoryPicker();

Future<void> pickAndUploadDirectory(BuildContext context, String parent) async {
  final dir = await showDirectoryPicker().toDart;
  processDirs(dir);
}

Future<void> processDirs(web.FileSystemDirectoryHandle dir) async {
  print('Processing ${dir.name}');
  final it = dir.entries().asStream();
  it.forEach((e) async {
    final l = e.toDart;

    if (l[1].isA<web.FileSystemDirectoryHandle>()) {
      await processDirs(l[1] as web.FileSystemDirectoryHandle);
    } else if (l[1].isA<web.FileSystemFileHandle>()) {
      final file = await (l[1] as web.FileSystemFileHandle).getFile().toDart;
      final reader = web.FileReader();
      reader.onload = () {
        // final bytes = (reader.result as JSArrayBuffer).toDart;
        print('contents of ${file.name}: ${reader.result}');
      }.toJS;

      reader.readAsText(file);
      // reader.readAsArrayBuffer(file);
    }
  });
}

extension on web.FileSystemDirectoryHandle {
  external JsAsyncIterator<JSArray> entries();
}

extension type JsAsyncIterator<T extends JSAny>._(JSObject _) implements JSObject {
  external JSPromise<JsAsyncIteratorState<T>> next();

  Stream<T> asStream() async* {
    while (true) {
      final result = await next().toDart;
      if (result.done) break;
      yield result.value;
    }
  }
}

extension type JsAsyncIteratorState<T extends JSAny>._(JSObject _) implements JSObject {
  external bool get done;

  external T get value;
}
