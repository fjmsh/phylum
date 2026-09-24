import 'package:flutter/material.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/explorer/menu/menu_option.dart';
import 'package:phylum/ui/explorer/util/icon_extensions.dart';
import 'package:provider/provider.dart';

import 'option_groups.dart';

void showMenuOptionsBottomSheet({
  required BuildContext context,
  required MenuOptionGroups groups,
  required Iterable<Resource> resources,
  required void Function(MenuOption option) onOptionSelected,
}) async {
  final account = context.read<PhylumAccount>();
  final items = groups
      .map(
        (group) => group.map(
          (option) => ListTile(
            visualDensity: VisualDensity.adaptivePlatformDensity,
            leading: Icon(option.icon),
            title: Text(option.text),
            onTap: () {
              onOptionSelected(option);
              Navigator.of(context).pop();
            },
          ),
        ),
      )
      .fold<Iterable<Widget>>([], (acc, e) {
        if (e.isEmpty) {
          return acc;
        }
        if (acc.isEmpty) {
          return e;
        }
        return [...acc, const Divider(), ...e];
      })
      .toList(growable: false);

  if (!context.mounted) return;
  showModalBottomSheet(
    showDragHandle: true,
    context: context,
    isScrollControlled: true,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.2,
      maxChildSize: 1.0,
      expand: false,
      snap: true,
      snapSizes: [0.4, 1.0],
      builder: (context, controller) {
        return SafeArea(
          child: CustomScrollView(
            controller: controller,
            slivers: [
              PinnedHeaderSliver(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    // border: Border(bottom: Divider.createBorderSide(context)),
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 16.0,
                      right: 16,
                      bottom: 8,
                    ),
                    child: Row(
                      spacing: 16,
                      children: [
                        if (resources.length == 1)
                          IconTheme(
                            data: IconThemeData(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                            child: resources.first.getIcon(account),
                          ),
                        resources.length == 1
                            ? Text(
                                resources.first.name,
                                softWrap: false,
                                overflow: TextOverflow.fade,
                                maxLines: 1,
                                style: Theme.of(context).textTheme.titleMedium,
                              )
                            : Text(
                                '${resources.length} items',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverList(delegate: SliverChildListDelegate(items)),
            ],
          ),
        );
      },
    ),
  );
}
