import 'package:flutter/material.dart';
import 'package:phylum/ui/layout/action_queue_status_notifier.dart';
import 'package:provider/provider.dart';

enum _ServerStatus {
  done(Icons.sync, 'Up-to-date'),
  paused(Icons.sync_disabled, 'Sync Paused'),
  syncing(Icons.cloud_sync, 'Syncing'),
  error(Icons.sync_problem, 'Error'),
  unreachable(Icons.cloud_off, 'Unreachable');

  const _ServerStatus(this.icon, this.text);

  final IconData icon;
  final String text;
}

class ServerStatusButton extends StatelessWidget {
  final void Function()? onTap;
  const ServerStatusButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ActionQueueStatusNotifier>();
    _ServerStatus state = _ServerStatus.done;
    if (notifier.unreachable) state = _ServerStatus.unreachable;
    if (notifier.errorCount > 0) state = _ServerStatus.error;
    if (notifier.submittingCount > 0) state = _ServerStatus.syncing;
    if (notifier.paused) state = _ServerStatus.paused;
    return ListTile(
      leading: Icon(state.icon),
      title: const Text('Server Status'),
      subtitle: Text(state.text),
      onTap: onTap,
    );
  }
}
