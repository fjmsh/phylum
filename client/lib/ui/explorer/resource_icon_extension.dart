import 'package:flutter/material.dart';
import 'package:phylum/libphylum/db/db.dart';

extension ResourceIconExtension on Resource {
  Icon getIcon() {
    if (dir) return const Icon(Icons.folder);

    if (contentType.startsWith("image")) {
      return const Icon(Icons.image);
    } else if (contentType.startsWith("video")) {
      return const Icon(Icons.movie);
    } else if (contentType.startsWith("audio")) {
      return const Icon(Icons.headphones);
    } else if (contentType.startsWith("text")) {
      return const Icon(Icons.article);
    }
    return const Icon(Icons.insert_drive_file);
  }
}
