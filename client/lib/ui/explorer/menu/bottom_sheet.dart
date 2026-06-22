import 'package:flutter/material.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/explorer/util/icon_extensions.dart';
import 'package:phylum/ui/explorer/menu/menu_option.dart';
import 'package:provider/provider.dart';

import 'option_groups.dart';

void showMenuOptionsBottomSheet(
  BuildContext context,
  MenuOptionGroups options,
  Iterable<Resource> resources,
) async {
  final account = context.read<PhylumAccount>();
  final items = await buildPopupMenuItems(account, options, resources);
  if (!context.mounted) return;
  final selected = await showModalBottomSheet(
    context: context,
    builder: (context) => ListView(
      shrinkWrap: true,
      children: [
        DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            border: Border(bottom: Divider.createBorderSide(context)),
          ),
          child: resources.length == 1
              ? ListTile(
                  leading: resources.first.getIcon(account),
                  title: Text(
                    resources.first.name,
                    softWrap: false,
                    overflow: TextOverflow.fade,
                    maxLines: 1,
                  ),
                )
              : ListTile(title: Text('${resources.length} items')),
        ),
        ...items,
      ],
    ),
  );

  if (!context.mounted || selected == null) {
    return;
  }
  handleOption(context, resources, selected);
}
