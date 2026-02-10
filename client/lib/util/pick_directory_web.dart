import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:phylum/libphylum/repositories/resource_repository.dart';
import 'package:phylum/util/upload_utils.dart';
import 'package:web/web.dart' as web;

bool _folderUploadSupported = web.window.has('showDirectoryPicker');
bool get folderUploadSupported => _folderUploadSupported;

Future<void> pickAndUploadDirectory(BuildContext context, String folderId) async {
  final dir =
      await (web.window.callMethod('showDirectoryPicker'.toJS) as JSPromise<web.FileSystemDirectoryHandle>).toDart;
  final tree = await enumerateDir(dir, '');
  uploadDirTree(context, folderId, tree);
}

Future<DirTree> enumerateDir(web.FileSystemDirectoryHandle dir, String prefix) async {
  if (prefix.isNotEmpty) prefix += '/';
  final files = <UploadFile>[];
  final dirs = <String>['$prefix${dir.name}'];
  int totalSize = 0;

  final entries = dir.entries();
  while (true) {
    final result = await entries.next().toDart;
    if (result.done) break;
    final handle = result.value.toDart;

    if (handle[1].isA<web.FileSystemDirectoryHandle>()) {
      final subtree = await enumerateDir(handle[1] as web.FileSystemDirectoryHandle, '$prefix${dir.name}');
      dirs.addAll(subtree.dirs);
      files.addAll(subtree.files);
      totalSize += subtree.totalSize;
    } else if (handle[1].isA<web.FileSystemFileHandle>()) {
      final f = handle[1] as web.FileSystemFileHandle;
      final file = await f.getFile().toDart;
      totalSize += file.size;
      files.add(UploadFile(size: file.size, stream: byteStream(file), path: '$prefix${dir.name}/${file.name}'));
    }
  }
  return DirTree(
    totalSize: totalSize,
    files: files,
    dirs: dirs,
  );
}

Stream<Uint8List> byteStream(web.File file) async* {
  // Hack: wait to allocate the array buffer until after the first yield
  yield Uint8List(0);

  const int size = 64 * 1024;
  final stream = file.stream();
  final reader = stream.getReader(web.ReadableStreamGetReaderOptions(mode: "byob")) as web.ReadableStreamBYOBReader;
  final buffer = JSArrayBuffer(size);
  final view = JSUint8Array(buffer, 0, size);

  var result = await reader.read(view).toDart;
  while (!result.done) {
    final buf = result.value.dartify() as Uint8List;
    yield buf;
    result = await reader.read(buf.toJS).toDart;
  }
}

extension on web.FileSystemDirectoryHandle {
  external JsAsyncIterator<JSArray> entries();
}

extension type JsAsyncIterator<T extends JSAny>._(JSObject _) implements JSObject {
  external JSPromise<JsAsyncIteratorState<T>> next();
}

extension type JsAsyncIteratorState<T extends JSAny>._(JSObject _) implements JSObject {
  external bool get done;

  external T get value;
}
