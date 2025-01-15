import 'package:flutter/material.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';
import 'package:state_notifier/state_notifier.dart';

class ActionQueueStatusNotifier extends ChangeNotifier {
  late final RemoveListener removeListenerCallback;
  List<PhylumAction>? last;
  final Map<PhylumAction, RemoveListener> _listeners = {};
  final Map<PhylumAction, ActionStatus> _statusMap = {};
  bool paused = false;
  bool unreachable = false;

  int get submittingCount => _count<ActionStatusUploading>();
  int get errorCount => _count<ActionStatusError>();
  int _count<T extends ActionStatus>() => _statusMap.values.fold(0, (acc, status) => status is T ? acc + 1 : acc);

  ActionQueueStatusNotifier(PhylumActionQueue queue) {
    removeListenerCallback = queue.addListener((state) {
      if (state.actions != last) {
        for (final action in state.actions) {
          if (!_listeners.containsKey(action)) {
            _listeners[action] = action.statusNotifier.addListener((status) {
              // Ignore progress updates
              if (_statusMap[action].runtimeType != status.runtimeType) {
                if (status is ActionStatusDone) {
                  final l = _listeners.remove(action);
                  _statusMap.remove(action);
                  if (l != null) {
                    Future.microtask(() => l());
                  }
                } else {
                  _statusMap[action] = status;
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
