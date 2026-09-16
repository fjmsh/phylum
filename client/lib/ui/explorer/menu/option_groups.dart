import 'package:flutter/material.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';

import 'menu_option.dart';

typedef MenuOptionGroups = Iterable<Iterable<MenuOption>>;

Future<Iterable<PopupMenuEntry<MenuOption>>> buildPopupMenuItems(
  PhylumAccount account,
  MenuOptionGroups options,
  Iterable<Resource> resources, {
  bool hideDisabled = true,
  void Function(MenuOption)? onTap,
}) async {
  final availableOptions = await Future.wait(
    options.map(
      (group) async => Future.wait(
        group.map((o) async {
          final enabled = await o.filter(account, resources);
          return hideDisabled && !enabled
              ? null
              : PopupMenuItem(
                  onTap: onTap == null ? null : () => onTap(o),
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

  final m = availableOptions.fold(<PopupMenuEntry<MenuOption>>[], (acc, e) {
    if (e.isEmpty) {
      return acc;
    }
    if (acc.isEmpty) {
      return e.toList(growable: false);
    }
    return [...acc, const PopupMenuDivider(), ...e];
  });
  return m;
}
