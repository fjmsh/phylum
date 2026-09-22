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
          return await option.enabled(account, resources) ? option : null;
        }),
      ).then((options) => options.whereType<MenuOption>()),
    ),
  );
}
