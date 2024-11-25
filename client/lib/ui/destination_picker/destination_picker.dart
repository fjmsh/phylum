import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:phylum/app_shortcuts.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/explorer/resource_icon_extension.dart';
import 'package:phylum/util/upload_utils.dart';
import 'package:provider/provider.dart';

import 'controller.dart';

class DestinationPicker extends StatefulWidget {
  const DestinationPicker({super.key});

  @override
  State<DestinationPicker> createState() => _DestinationPickerState();

  static Future<String?> show(BuildContext context, Resource startingFolder) {
    return showDialog(
      context: context,
      builder: (context) => StateNotifierProvider<DestinationPickerController, DestinationPickerState>(
        create: (context) => DestinationPickerController(startingFolder),
        builder: (_, __) => const DestinationPicker(),
      ),
    );
  }
}

class _DestinationPickerState extends State<DestinationPicker> {
  final FocusNode node = FocusNode(debugLabel: 'Destination Explorer');

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pick Destination'),
        actions: [
          IconButton(
              onPressed: () {
                createDirectory(context, context.read<DestinationPickerState>().folder.id);
              },
              icon: Icon(Icons.create_new_folder_outlined))
        ],
      ),
      body: FocusScope(
        child: Actions(
          actions: {
            NavUpIntent: CallbackAction<NavUpIntent>(onInvoke: (i) async {
              final parentId = context.read<DestinationPickerState>().folder.parent;
              if (parentId != null) {
                final controller = context.read<DestinationPickerController>();
                final parent = await context.read<PhylumAccount>().resourceRepository.getResource(parentId);
                controller.updateFolder(parent!);
              }
              node.requestFocus();
              return null;
            }),
          },
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Expanded(
                child: Focus(
                  autofocus: true,
                  focusNode: node,
                  child: ExcludeFocus(child: const DestinationFolderView()),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: Navigator.of(context).pop, child: Text('Cancel')),
                    ElevatedButton(
                      onPressed: context.select<DestinationPickerState, bool>((state) => state.folder.id != state.initialFolder)
                          ? null
                          : () => Navigator.of(context).pop(context.read<DestinationPickerState>().folder.id),
                      child: Text('OK'),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class DestinationFolderView extends StatelessWidget {
  const DestinationFolderView({super.key});

  @override
  Widget build(BuildContext context) {
    final id = context.select<DestinationPickerState, String>((state) => state.folder.id);
    return StreamBuilder(
        stream: context.read<PhylumAccount>().resourceRepository.watchChildren(id),
        builder: (context, snapshot) {
          final data = snapshot.data;
          if (data == null) return Center(child: CircularProgressIndicator());
          return ListView.builder(
            itemBuilder: (BuildContext context, int index) {
              final r = data[index];
              return ListTile(
                visualDensity: VisualDensity.compact,
                leading: r.getIcon(),
                title: Text(r.name),
                enabled: r.dir,
                onTap: () => context.read<DestinationPickerController>().updateFolder(r),
              );
            },
            itemCount: data.length,
          );
        });
  }
}
