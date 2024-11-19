import 'package:flutter/material.dart';
import 'package:phylum/app_shortcuts.dart';
import 'package:phylum/libphylum/actions/action_resource_delete.dart';
import 'package:phylum/libphylum/actions/action_resource_move.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/common/responsive_dialog.dart';
import 'package:phylum/ui/explorer/resource_icon_extension.dart';
import 'package:phylum/ui/explorer/resource_info_view.dart';
import 'package:phylum/util/dialogs.dart';
import 'package:provider/provider.dart';

enum MenuOption {
  details(Icons.info_outline, 'Details', isSingle),
  download(Icons.download, 'Download', all),
  bookmark(Icons.bookmark_add_outlined, 'Add To Bookmarks', all),
  rename(Icons.drive_file_rename_outline, 'Rename', isSingle),
  move(Icons.drive_file_move_outlined, 'Move To', all),
  copy(Icons.copy, 'Copy To', all),
  delete(Icons.delete_outline, 'Delete', all),
  permissions(Icons.people_alt_outlined, 'Permissions', isSingle),
  publinks(Icons.public, 'Public Access', isSingle),
  newFolder(Icons.create_new_folder_outlined, 'New Folder', isSingle),
  uploadFiles(Icons.upload_file_outlined, 'Upload File(s)', isSingle),
  uploadFolders(Icons.drive_folder_upload_outlined, 'Upload Folder(s)', isSingle),
  ;

  const MenuOption(this.icon, this.text, this.filter);

  final IconData icon;
  final String text;
  final bool Function(Iterable<Resource> resources) filter;
}

const resourceOptionsGroups = [
  [
    MenuOption.download,
    MenuOption.rename,
    MenuOption.move,
    MenuOption.copy,
    MenuOption.delete,
  ],
  [
    MenuOption.bookmark,
    MenuOption.permissions,
    MenuOption.publinks,
  ],
  [
    MenuOption.details,
  ],
];

final explorerOptionsGroups = [
  [
    MenuOption.newFolder,
    MenuOption.uploadFiles,
    MenuOption.uploadFolders,
  ],
  [
    MenuOption.bookmark,
    MenuOption.permissions,
    MenuOption.publinks,
  ],
  [
    MenuOption.details,
  ]
];

bool isSingle(Iterable<Resource> resources) => resources.length == 1;

bool none(Iterable<Resource> resources) => false;

bool all(Iterable<Resource> resources) => true;

class ResourceOptionsButton extends StatelessWidget {
  final Resource r;

  const ResourceOptionsButton({super.key, required this.r});

  @override
  Widget build(BuildContext context) {
    final resources = [r];
    return MediaQuery.sizeOf(context).width < 800
        ? IconButton(icon: Icon(Icons.adaptive.more), onPressed: () => showResourceOptions(context, resources))
        : ListTileTheme(
            data: ListTileThemeData(visualDensity: VisualDensity.compact),
            child: PopupMenuButton(
              itemBuilder: (context) => buildChildPopupMenuItems(context, resources).toList(growable: false),
              onSelected: (o) => handleResourceOption(context, resources, o),
            ),
          );
  }
}

void showResourceOptions(BuildContext context, Iterable<Resource> resources) async {
  final option = await showModalBottomSheet(context: context, builder: (context) => ResourceOptionsList(resources: resources));
  if (!context.mounted || option == null) {
    return;
  }
  handleResourceOption(context, resources, option);
}

void handleResourceOption(BuildContext context, Iterable<Resource> resources, MenuOption option) async {
  final account = context.read<PhylumAccount>();
  switch (option) {
    case MenuOption.rename:
      assert(resources.length == 1);
      final name = await showInputDialog(context, title: 'Rename', preset: resources.first.name);
      if (name != null) {
        account.addAction(ResourceMoveAction(r: resources.first, name: name));
      }
      break;
    case MenuOption.move:
      break;
    case MenuOption.copy:
      break;
    case MenuOption.delete:
      final name = resources.length == 1 ? resources.first.name : '${resources.length} items';
      final confirm = await showAlertDialog(context, title: 'Delete $name?', positiveText: 'YES', negativeText: 'NO') ?? false;
      if (confirm) {
        for (final r in resources) {
          account.addAction(ResourceDeleteAction(r: r));
        }
      }
      break;
    case MenuOption.details:
      showReponsiveDialog(context, 'Details', (context) => ResourceInfoView(resource: resources.first));
      break;
    case MenuOption.permissions:
    case MenuOption.publinks:
    case MenuOption.download:
    case MenuOption.bookmark:
      break;
    case MenuOption.newFolder:
      Actions.maybeInvoke(context, const NewFolderIntent());
    case MenuOption.uploadFiles:
      Actions.maybeInvoke(context, const UploadFilesIntent());
    case MenuOption.uploadFolders:
      Actions.maybeInvoke(context, const UploadFolderIntent());
  }
}

class ResourceOptionsList extends StatelessWidget {
  final Iterable<Resource> resources;

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

Iterable<Widget> buildBottomSheetItems(BuildContext context, Iterable<Resource> resources) {
  return resourceOptionsGroups
      .map((group) => group.map((o) => ListTile(
            visualDensity: VisualDensity.adaptivePlatformDensity,
            leading: Icon(o.icon),
            title: Text(o.text),
            onTap: o.filter(resources) ? () => Navigator.of(context).pop(o) : null,
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

Iterable<PopupMenuEntry> buildChildPopupMenuItems(BuildContext context, Iterable<Resource> resources) {
  return _buildPopupMenuItems(context, resourceOptionsGroups, resources);
}

Iterable<PopupMenuEntry> buildExplorerPopupMenuItems(BuildContext context, Iterable<Resource> resources) {
  return _buildPopupMenuItems(context, explorerOptionsGroups, resources);
}

Iterable<PopupMenuEntry> _buildPopupMenuItems(BuildContext context, Iterable<Iterable<MenuOption>> options, Iterable<Resource> resources) {
  return options
      .map((group) => group.map((o) => PopupMenuItem(
            value: o,
            enabled: o.filter(resources),
            child: ListTile(
              visualDensity: VisualDensity.adaptivePlatformDensity,
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
