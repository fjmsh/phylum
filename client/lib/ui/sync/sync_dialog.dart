import 'package:flutter/material.dart';
import 'package:phylum/ui/sync/action_queue_list.dart';

class SyncDialog extends StatelessWidget {
  const SyncDialog({super.key});

  static void show(BuildContext context) {
    showDialog(context: context, builder: (context) => const SyncDialog());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Actions'),
      ),
      body: const ActionQueueList(),
    );
  }
}
