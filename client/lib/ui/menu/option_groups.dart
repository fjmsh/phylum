import 'package:flutter/material.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';

import 'menu_option.dart';

typedef MenuOptionGroups = Iterable<Iterable<MenuOption>>;

const resourceOptions = [
  [
    MenuOption.download,
    MenuOption.rename,
    MenuOption.move,
    MenuOption.copy,
    MenuOption.delete,
  ],
  [
    MenuOption.bookmarkAdd,
    MenuOption.bookmarkRemove,
    MenuOption.permissions,
    MenuOption.publinks,
  ],
  [
    MenuOption.details,
  ],
];

const trashedResourceOptions = [
  [
    MenuOption.restore,
    MenuOption.deleteForever,
  ],
  [
    MenuOption.details,
  ],
];

final parentFolderOptions = [
  [
    MenuOption.newFolder,
    MenuOption.uploadFiles,
    MenuOption.uploadFolders,
  ],
  [
    MenuOption.bookmarkAdd,
    MenuOption.bookmarkRemove,
    MenuOption.permissions,
    MenuOption.publinks,
  ],
  [
    MenuOption.details,
  ]
];

Future<Iterable<PopupMenuEntry<MenuOption>>> buildPopupMenuItems(
  PhylumAccount account,
  MenuOptionGroups options,
  Iterable<Resource> resources, [
  bool hideDisabled = true,
]) async {
  final availableOptions = await Future.wait(
    options.map(
      (group) async => Future.wait(
        group.map((o) async {
          final enabled = await o.filter(account, resources);
          return hideDisabled && !enabled
              ? null
              : PopupMenuItem(
                  value: o,
                  enabled: enabled,
                  child: ListTile(
                    visualDensity: VisualDensity.adaptivePlatformDensity,
                    leading: Icon(o.icon),
                    title: Text(o.text),
                  ),
                );
        }),
      ).then((items) => items.whereType<PopupMenuEntry<MenuOption>>()),
    ),
  );

  final m = availableOptions.fold(
    <PopupMenuEntry<MenuOption>>[],
    (acc, e) {
      if (e.isEmpty) {
        return acc;
      }
      if (acc.isEmpty) {
        return e.toList(growable: false);
      }
      return [...acc, PopupMenuDivider(), ...e];
    },
  );
  return m;
}
