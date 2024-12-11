import 'package:flutter/material.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';
import 'package:state_notifier/state_notifier.dart';

class ActionQueueStatusNotifier extends ChangeNotifier {
  final Map<QueuedAction<PhylumAccount>, RemoveListener> _listeners = {};
  final Map<QueuedAction<PhylumAccount>, ActionStatus> _statusMap = {};
  List<QueuedAction<PhylumAccount>>? last;
  late final RemoveListener removeListenerCallback;
  bool paused = false;
  bool unreachable = false;

  int get submittingCount => _count<ActionStatusUploading>();
  int get errorCount => _count<ActionStatusError>();
  int _count<T extends ActionStatus>() => _statusMap.values.fold(0, (acc, status) => status is T ? acc + 1 : acc);

  final _statusActionsMap = <Type, List<QueuedAction<PhylumAccount>>>{};
  List<QueuedAction<PhylumAccount>> _actionsByStatus(Type t) {
    return _statusActionsMap.putIfAbsent(
      t,
      () => List.of(_statusMap.entries.where((e) => e.value.runtimeType == t).map((e) => e.key), growable: false),
    );
  }

  List<QueuedAction<PhylumAccount>> get failedActions {
    return _actionsByStatus(ActionStatusError);
  }

  List<QueuedAction<PhylumAccount>> get submittingActions {
    return _actionsByStatus(ActionStatusUploading);
  }

  List<QueuedAction<PhylumAccount>> get readyActions {
    return _actionsByStatus(ActionStatusReady);
  }

  List<QueuedAction<PhylumAccount>> get waitingActions {
    return _actionsByStatus(ActionStatusWaiting);
  }

  ActionQueueStatusNotifier(PhylumActionQueue queue) {
    removeListenerCallback = queue.addListener((state) {
      if (state.actions != last) {
        for (final action in state.actions) {
          if (!_listeners.containsKey(action)) {
            _listeners[action] = action.statusNotifier.addListener((status) {
              // Ignore progress updates
              if (_statusMap[action].runtimeType != status.runtimeType) {
                _statusActionsMap.remove(status.runtimeType);
                _statusActionsMap.remove(_statusMap[action].runtimeType);
                _statusMap[action] = status;
                if (status is ActionStatusDone) {
                  Future.microtask(() {
                    _listeners[action]?.call();
                    _listeners.remove(action);
                    _statusMap.remove(action);
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
