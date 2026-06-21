import 'package:flutter/material.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';

const IconData folderIcon = Icons.folder;
const IconData defaultFileIcon = Icons.insert_drive_file;

extension ResourceIcon on Resource {
  Widget getIcon(PhylumAccount account) {
    if (dir) return const Icon(folderIcon);

    return StreamBuilder(
      stream: account.db.latestVersion(id).watchSingleOrNull(),
      builder: (context, snapshot) {
        return snapshot.data?.getIcon() ?? const Icon(Icons.insert_drive_file);
      },
    );
  }
}

extension ResourceVersionIcon on ResourceVersion {
  Icon getIcon() {
    if (mimeType.startsWith("image")) {
      return const Icon(Icons.image);
    } else if (mimeType.startsWith("video")) {
      return const Icon(Icons.movie);
    } else if (mimeType.startsWith("audio")) {
      return const Icon(Icons.headphones);
    } else if (mimeType.startsWith("text")) {
      return const Icon(Icons.article);
    }
    return const Icon(defaultFileIcon);
  }
}
