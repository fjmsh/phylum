import 'package:flutter/material.dart';
import 'package:phylum/ui/sync/action_queue_list.dart';

class SyncDialog extends StatelessWidget {
  const SyncDialog({super.key});

  static void show(BuildContext context) {
    showDialog(context: context, builder: (context) => const SyncDialog());
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    if (size.width < 600) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Sync'),
        ),
        body: const ActionQueueList(),
      );
    } else {
      return Center(
        child: SizedBox(
          width: 800,
          child: Card(
            margin: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                AppBar(title: const Text('Sync'), leading: const CloseButton(), backgroundColor: Colors.transparent),
                // ListTile(
                //   leading: IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close)),
                //   title: const Text('Pending Actions'),
                // ),
                const Expanded(child: ActionQueueList()),
              ],
            ),
          ),
        ),
      );
    }
  }
}
