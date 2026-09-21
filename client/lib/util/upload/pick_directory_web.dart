import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/material.dart';
import 'package:phylum/util/upload/upload_utils.dart';
import 'package:web/web.dart' as web;

import 'filesystem_web.dart';

bool _folderUploadSupported = web.window.has('showDirectoryPicker');
bool get folderUploadSupported => _folderUploadSupported;

Future<void> pickAndUploadDirectory(
  BuildContext context,
  String folderId,
) async {
  final dir =
      await (web.window.callMethod('showDirectoryPicker'.toJS)
              as JSPromise<web.FileSystemDirectoryHandle>)
          .toDart;
  if (!context.mounted) return;
  final tree = await enumerateDirectory(context, dir);
  if (!context.mounted) return;
  uploadDirTree(context, folderId, tree);
}
