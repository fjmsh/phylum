import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:phylum/ui/explorer/gesture_handlers/external_drop_region.dart';
import 'package:phylum/util/upload/filesystem_io.dart';
import 'package:phylum/util/upload/upload_utils.dart';

Future<DirTree> enumerateDropItemPlatform(DropItem item) {
  if (Platform.isMacOS) {
    return enumerateDirectory(item.path);
  }
  return enumerateDropItem(item, '');
}
