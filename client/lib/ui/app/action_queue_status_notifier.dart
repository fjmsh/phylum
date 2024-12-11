import 'package:flutter/material.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';
import 'package:state_notifier/state_notifier.dart';

const _order = {
  ActionStatusDone: 0,
  ActionStatusError: 1,
  ActionStatusUploading: 2,
  ActionStatusReady: 3,
  ActionStatusWaiting: 4,
};

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

  List<QueuedAction<PhylumAccount>>? _orderedActions;
  List<QueuedAction<PhylumAccount>> get orderedActions {
    _orderedActions ??= List.of(_statusMap.keys, growable: false)
      ..sort((a, b) {
        if (_statusMap[a] == _statusMap[b]) {
          return a.id.compareTo(b.id);
        }
        return _order[_statusMap[a].runtimeType]! - _order[_statusMap[b].runtimeType]!;
      });
    return _orderedActions!;
  }

  ActionQueueStatusNotifier(PhylumActionQueue queue) {
    removeListenerCallback = queue.addListener((state) {
      if (state.actions != last) {
        for (final action in state.actions) {
          if (!_listeners.containsKey(action)) {
            _listeners[action] = action.statusNotifier.addListener((status) {
              // Ignore progress updates
              if (_statusMap[action].runtimeType != status.runtimeType) {
                _orderedActions = null;
                if (status is ActionStatusDone) {
                  _listeners.remove(action)?.call();
                  _statusMap.remove(action);
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
