import 'package:flutter/material.dart';
import 'package:phylum/libphylum/actions/action_resource_delete.dart';
import 'package:phylum/libphylum/actions/action_resource_move.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/explorer/resource_icon_extension.dart';
import 'package:phylum/util/dialogs.dart';
import 'package:provider/provider.dart';

enum ResourceOption {
  details(Icons.info_outline, 'Details', isSingle),
  download(Icons.download, 'Download', all),
  bookmark(Icons.bookmark_add_outlined, 'Add To Bookmarks', all),
  rename(Icons.drive_file_rename_outline, 'Rename', isSingle),
  move(Icons.drive_file_move_outlined, 'Move To', all),
  copy(Icons.copy, 'Copy To', all),
  delete(Icons.delete_outline, 'Delete', all),
  permissions(Icons.people_alt_outlined, 'Permissions', isSingle),
  publinks(Icons.public, 'Public Access', isSingle),
  ;

  const ResourceOption(this.icon, this.text, this.filter);

  final IconData icon;
  final String text;
  final bool Function(List<Resource> resources) filter;
}

const optionsGroups = [
  [
    ResourceOption.download,
    ResourceOption.rename,
    ResourceOption.move,
    ResourceOption.copy,
    ResourceOption.delete,
  ],
  [
    ResourceOption.bookmark,
    ResourceOption.permissions,
    ResourceOption.publinks,
  ],
  [
    ResourceOption.details,
  ],
];

bool isSingle(List<Resource> resources) => resources.length == 1;

bool none(List<Resource> resources) => false;

bool all(List<Resource> resources) => true;

class ResourceOptionsButton extends StatelessWidget {
  final Resource r;

  const ResourceOptionsButton({super.key, required this.r});

  @override
  Widget build(BuildContext context) {
    final account = context.read<PhylumAccount>();
    return MediaQuery.sizeOf(context).width < 800
        ? IconButton(icon: Icon(Icons.adaptive.more), onPressed: () => showResourceOptions(context, account))
        : ListTileTheme(
            data: ListTileThemeData(visualDensity: VisualDensity.compact),
            child: PopupMenuButton(
              itemBuilder: (context) => buildPopupMenuItems(context, [r]).toList(growable: false),
              onSelected: (o) => handleResourceOption(context, account, o),
            ),
          );
  }

  void showResourceOptions(BuildContext context, PhylumAccount account) async {
    final option = await showModalBottomSheet(context: context, builder: (context) => ResourceOptionsList(resources: [r]));
    if (!context.mounted || option == null) {
      return;
    }
    handleResourceOption(context, account, option);
  }

  void handleResourceOption(BuildContext context, final PhylumAccount account, ResourceOption option) async {
    switch (option) {
      case ResourceOption.details:
      case ResourceOption.rename:
        final name = await showInputDialog(context, title: 'Rename', preset: r.name);
        if (name != null) {
          account.addAction(ResourceMoveAction(r: r, name: name));
        }
        break;
      case ResourceOption.move:
        break;
      case ResourceOption.copy:
        break;
      case ResourceOption.delete:
        final confirm = await showAlertDialog(context, title: 'Delete ${r.name}?', positiveText: 'YES', negativeText: 'NO') ?? false;
        if (confirm) {
          account.addAction(ResourceDeleteAction(r: r));
        }
        break;
      case ResourceOption.permissions:
      case ResourceOption.publinks:
      case ResourceOption.download:
      case ResourceOption.bookmark:
    }
  }
}

class ResourceOptionsList extends StatelessWidget {
  final List<Resource> resources;

  const ResourceOptionsList({super.key, required this.resources});

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      children: [
        resources.length == 1
            ? ListTile(
                leading: resources.first.getIcon(),
                title: Text(resources.first.name),
              )
            : ListTile(
                title: Text('${resources.length} items'),
              ),
        ...buildBottomSheetItems(context, resources)
      ],
    );
  }
}

Iterable<Widget> buildBottomSheetItems(BuildContext context, List<Resource> resources) {
  return optionsGroups
      .map((group) => group.map((o) => ListTile(
            leading: Icon(o.icon),
            title: Text(o.text),
            onTap: () => Navigator.of(context).pop(o),
          )))
      .fold<Iterable<Widget>>(
    <Widget>[],
    (acc, e) {
      if (e.isEmpty) {
        return acc;
      }
      if (acc.isEmpty) {
        return e;
      }
      return [...acc, Divider(), ...e];
    },
  );
}

Iterable<PopupMenuEntry> buildPopupMenuItems(BuildContext context, List<Resource> resources) {
  return optionsGroups
      .map((group) => group.map((o) => PopupMenuItem(
            value: o,
            child: ListTile(
              leading: Icon(o.icon),
              title: Text(o.text),
            ),
          )))
      .fold(
    <PopupMenuEntry>[],
    (acc, e) {
      if (e.isEmpty) {
        return acc;
      }
      if (acc.isEmpty) {
        return e;
      }
      return [...acc, PopupMenuDivider(), ...e];
    },
  );
}
