import 'package:flutter/material.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';

import 'menu_option.dart';

typedef MenuOptionGroups = Iterable<Iterable<MenuOption>>;

Future<List<Iterable<MenuOption>>> getEnabledOptions(
  PhylumAccount account,
  MenuOptionGroups groups,
  Iterable<Resource> resources,
) async {
  return Future.wait(
    // Filter out disabled options
    groups.map(
      (group) async => Future.wait(
        group.map((option) async {
          return await option.filter(account, resources) ? option : null;
        }),
      ).then((options) => options.whereType<MenuOption>()),
    ),
  );
}

Future<Iterable<Widget>> buildPopupMenuItems(
  PhylumAccount account,
  MenuOptionGroups groups,
  Iterable<Resource> resources, {
  required void Function(MenuOption)? onTap,
}) async {
  return Future.wait(
        // Filter out disabled options
        groups.map(
          (group) async => Future.wait(
            group.map((option) async {
              return await option.filter(account, resources) ? option : null;
            }),
          ).then((options) => options.whereType<MenuOption>()),
        ),
      )
      .then(
        // Create Widgets
        (groups) => groups.map(
          (group) => group.map(
            (option) => ListTile(
              visualDensity: VisualDensity.adaptivePlatformDensity,
              leading: Icon(option.icon),
              title: Text(option.text),
            ),
          ),
        ),
      )
      .then(
        // Flatten with dividers
        (items) => items.fold<Iterable<Widget>>([], (acc, e) {
          if (e.isEmpty) {
            return acc;
          }
          if (acc.isEmpty) {
            return e.toList(growable: false);
          }
          return [...acc, const Divider(), ...e];
        }),
      );
}
