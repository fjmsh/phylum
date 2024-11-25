import 'package:flutter/material.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/explorer/resource_icon_extension.dart';
import 'package:provider/provider.dart';

class DestinationPicker extends StatefulWidget {
  final String startingFolderId;
  const DestinationPicker({super.key, required this.startingFolderId});

  @override
  State<DestinationPicker> createState() => _DestinationPickerState();

  static Future<String?> pick(BuildContext context, String startingFolderId) {
    return showDialog(
      context: context,
      builder: (context) => DestinationPicker(startingFolderId: startingFolderId),
    );
  }
}

class _DestinationPickerState extends State<DestinationPicker> {
  late String folderId;

  @override
  void initState() {
    super.initState();
    folderId = widget.startingFolderId;
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('build $folderId');
    return Scaffold(
      appBar: AppBar(title: Text('Pick Destination')),
      body: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
            child: DestinationFolderView(
              id: folderId,
              onFolderSelected: (id) => setState(() => folderId = id),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: Navigator.of(context).pop, child: Text('Cancel')),
                ElevatedButton(onPressed: folderId == widget.startingFolderId ? null : () => Navigator.of(context).pop(folderId), child: Text('OK')),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class DestinationFolderView extends StatelessWidget {
  final String id;
  final Function(String) onFolderSelected;

  DestinationFolderView({required this.id, required this.onFolderSelected}) : super(key: ValueKey(id));

  @override
  Widget build(BuildContext context) {
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
                onTap: () {
                  onFolderSelected(r.id);
                },
              );
            },
            itemCount: data.length,
          );
        });
  }
}
