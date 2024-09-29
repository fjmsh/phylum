import 'package:flutter/material.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';
import 'package:provider/provider.dart';
import 'package:state_notifier/state_notifier.dart';

class ActionQueueStatusNotifier extends ChangeNotifier {
  final Map<StateNotifier<ActionStatus>, RemoveListener> _listeners = {};
  final Map<StateNotifier<ActionStatus>, ActionStatus> _statusMap = {};
  List<QueuedAction<PhylumAccount>>? last;
  late final RemoveListener removeListenerCallback;
  bool paused = false;
  bool unreachable = false;

  int get submitting => _count<ActionStatusUploading>();
  int get error => _count<ActionStatusError>();
  int _count<T extends ActionStatus>() => _statusMap.values.fold(0, (acc, status) => status is T ? acc + 1 : acc);

  ActionQueueStatusNotifier(BuildContext context) {
    removeListenerCallback = context.read<PhylumActionQueue>().addListener((state) {
      if (state.actions != last) {
        for (final action in state.actions) {
          final notifier = action.statusNotifier;
          if (!_listeners.containsKey(notifier)) {
            _listeners[notifier] = notifier.addListener((status) {
              // Ignore progress updates
              if (_statusMap[notifier].runtimeType != status.runtimeType) {
                _statusMap[notifier] = status;
                if (status is ActionStatusDone) {
                  Future.microtask(() {
                    _listeners[notifier]?.call();
                    _listeners.remove(notifier);
                    _statusMap.remove(notifier);
                  });
                }
                notifyListeners();
              }
            }, fireImmediately: true);
          }
        }
        last = state.actions;
      }
      paused = state.paused;
      unreachable = state.unreachable;
      notifyListeners();
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    removeListenerCallback();
    super.dispose();
  }
}
