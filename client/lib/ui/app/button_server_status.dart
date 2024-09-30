import 'package:flutter/material.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/ui/app/action_queue_status_notifier.dart';
import 'package:phylum/ui/sync/sync_dialog.dart';
import 'package:provider/provider.dart';
import 'package:state_notifier/state_notifier.dart';

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

class ServerStatusButton extends StatefulWidget {
  const ServerStatusButton({super.key});

  @override
  State<ServerStatusButton> createState() => _ServerStatusButtonState();
}

class _ServerStatusButtonState extends State<ServerStatusButton> {
  void watchStatus(StateNotifier<ActionStatus> notifier) {}

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

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
      onTap: () {
        SyncDialog.show(context);
      },
    );
  }
}
