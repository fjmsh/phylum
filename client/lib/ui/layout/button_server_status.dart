import 'package:flutter/material.dart';
import 'package:phylum/ui/layout/action_queue_status_notifier.dart';
import 'package:phylum/ui/sync/sync_dialog.dart';
import 'package:provider/provider.dart';

enum _SyncStatus {
  done(Icons.cloud_done, 'Server up-to-date'),
  paused(Icons.pause, 'Sync Paused'),
  syncing(Icons.cloud_sync, 'Syncing'),
  error(Icons.sync_problem, 'Sync Error'),
  unreachable(Icons.cloud_off, 'Server Unreachable');

  const _SyncStatus(this.icon, this.text);

  final IconData icon;
  final String text;
}

class SyncStatusButton extends StatelessWidget {
  const SyncStatusButton({super.key});

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ActionQueueStatusNotifier>();
    _SyncStatus state = _SyncStatus.done;
    if (notifier.unreachable) state = _SyncStatus.unreachable;
    if (notifier.errorCount > 0) state = _SyncStatus.error;
    if (notifier.submittingCount > 0) state = _SyncStatus.syncing;
    if (notifier.paused) state = _SyncStatus.paused;
    return ListTile(
      leading: Icon(state.icon),
      title: Text(state.text, style: state == _SyncStatus.done ? null : TextStyle(fontWeight: FontWeight.bold)),
      onTap: () {
        Scaffold.maybeOf(context)?.closeDrawer();
        SyncDialog.show(context);
      },
    );
  }
}
