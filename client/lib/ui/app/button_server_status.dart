import 'package:flutter/material.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';
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
  final Map<StateNotifier<ActionStatus>, RemoveListener> _listeners = {};
  final Map<StateNotifier<ActionStatus>, ActionStatus> _statusMap = {};

  List<QueuedAction<PhylumAccount>>? last;
  late final RemoveListener removeListener;
  int get submitting => _count<ActionStatusSubmitting>();
  int get error => _count<ActionStatusError>();
  bool paused = false;
  bool unreachable = false;
  int _count<T extends ActionStatus>() => _statusMap.values.fold(0, (acc, status) => status is T ? acc + 1 : acc);

  void watchStatus(StateNotifier<ActionStatus> notifier) {}

  @override
  void initState() {
    super.initState();
    removeListener = context.read<PhylumActionQueue>().addListener((state) {
      if (state.actions != last) {
        for (final action in state.actions) {
          final notifier = action.statusNotifier;
          if (!_listeners.containsKey(notifier)) {
            _listeners[notifier] = notifier.addListener((status) {
              if (_statusMap[notifier] != status) {
                _statusMap[notifier] = status;
                if (status is ActionStatusDone) {
                  Future.microtask(() {
                    _listeners[notifier]?.call();
                    _listeners.remove(notifier);
                    _statusMap.remove(notifier);
                  });
                }
                setState(() {});
              }
            }, fireImmediately: true);
          }
        }
        last = state.actions;
      }
      setState(() {
        paused = state.paused;
        unreachable = state.unreachable;
      });
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    removeListener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _ServerStatus state = _ServerStatus.done;
    if (unreachable) state = _ServerStatus.unreachable;
    if (error > 0) state = _ServerStatus.error;
    if (submitting > 0) state = _ServerStatus.syncing;
    if (paused) state = _ServerStatus.paused;
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
