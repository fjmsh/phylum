import 'package:flutter/material.dart';
import 'package:phylum/libphylum/actions/action_resource_delete.dart';
import 'package:phylum/libphylum/actions/action_resource_rename.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/util/dialogs.dart';
import 'package:provider/provider.dart';

enum ResourceOption {
  rename(Icons.drive_file_rename_outline, 'Rename', canRename),
  copy(Icons.copy, 'Copy', canCopy),
  move(Icons.drive_file_move, 'Move', all),
  delete(Icons.delete, 'Delete', all);

  const ResourceOption(this.icon, this.text, this.filter);

  final IconData icon;
  final String text;
  final bool Function(List<Resource> resources) filter;
}

bool canRename(List<Resource> resources) => resources.length == 1;

bool canCopy(List<Resource> resources) => !resources.any((r) => r.dir);

bool all(List<Resource> resources) => true;

class ResourceOptionsButton extends StatelessWidget {
  final Resource r;

  const ResourceOptionsButton({super.key, required this.r});

  @override
  Widget build(BuildContext context) {
    final account = context.read<PhylumAccount>();
    return MediaQuery.of(context).size.width < 800
        ? IconButton(icon: Icon(Icons.adaptive.more), onPressed: () => showResourceOptions(context, account))
        : PopupMenuButton(
            itemBuilder: (context) => [
              for (final o in ResourceOption.values.where((o) => o.filter([r])))
                PopupMenuItem(
                    value: o,
                    child: ListTile(
                      title: Text(o.text),
                      leading: Icon(o.icon),
                      visualDensity: VisualDensity.compact,
                    )),
            ],
            onSelected: (o) => handleResourceOption(context, account, o),
          );
  }

  void showResourceOptions(BuildContext context, PhylumAccount account) async {
    final option = await showModalBottomSheet(context: context, builder: (context) => const ResourceOptionsList());
    if (!context.mounted) {
      return;
    }
    handleResourceOption(context, account, option);
  }

  void handleResourceOption(BuildContext context, final PhylumAccount account, ResourceOption option) async {
    switch (option) {
      case ResourceOption.rename:
        final name = await showInputDialog(context, title: 'Rename', preset: r.name);
        if (name != null) {
          account.addAction(ResourceRenameAction(r: r, name: name));
        }
        break;
      case ResourceOption.delete:
        final confirm = await showAlertDialog(context, title: 'Delete ${r.name}?', positiveText: 'YES', negativeText: 'NO') ?? false;
        if (confirm) {
          account.addAction(ResourceDeleteAction(r: r));
        }
        break;
      case ResourceOption.move:
        break;
      case ResourceOption.copy:
        break;
    }
  }
}

class ResourceOptionsList extends StatelessWidget {
  const ResourceOptionsList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      children: [
        for (final o in ResourceOption.values)
          ListTile(
            leading: Icon(o.icon),
            title: Text(o.text),
            onTap: () => Navigator.of(context).pop(o),
          ),
      ],
    );
  }
}
