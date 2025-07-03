import 'package:flutter/material.dart';
import 'package:phylum/ui/layout/sync_status_notifier.dart';
import 'package:phylum/ui/sync/sync_dialog.dart';
import 'package:provider/provider.dart';

class SyncStatusButton extends StatelessWidget {
  const SyncStatusButton({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.select<SyncStatusNotifier, SyncStatus>((notifier) => notifier.status);
    return ListTile(
      leading: Icon(state.icon),
      title: Text(state.text, style: state == SyncStatus.done ? null : TextStyle(fontWeight: FontWeight.bold)),
      onTap: () {
        Scaffold.maybeOf(context)?.closeDrawer();
        SyncDialog.show(context);
      },
    );
  }
}
