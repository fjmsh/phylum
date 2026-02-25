import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';
import 'package:provider/provider.dart';
import 'package:state_notifier/state_notifier.dart';

import 'action_view.dart';

const _order = {
  ActionStatusDone: 0,
  ActionStatusError: 1,
  ActionStatusUploading: 2,
  ActionStatusReady: 3,
  ActionStatusWaiting: 4,
};

class ActionsSliver extends StatefulWidget {
  const ActionsSliver({super.key});

  @override
  State<ActionsSliver> createState() => _ActionsSliverState();
}

class _ActionsSliverState extends State<ActionsSliver> {
  late final RemoveListener removeListenerCallback;
  List<PhylumAction>? last;
  final Map<PhylumAction, RemoveListener> _listeners = {};
  final Map<PhylumAction, ActionStatus> _statusMap = {};

  List<PhylumAction> actions = const [];

  @override
  void initState() {
    super.initState();
    final queue = context.read<PhylumActionQueue>();
    removeListenerCallback = queue.addListener((state) {
      if (state.actions != last) {
        for (final action in state.actions) {
          if (!_listeners.containsKey(action)) {
            _listeners[action] = action.statusNotifier.addListener((status) {
              // Ignore progress updates
              if (_statusMap[action].runtimeType != status.runtimeType) {
                if (status.terminal) {
                  final l = _listeners.remove(action);
                  _statusMap.remove(action);
                  if (l != null) {
                    Future.microtask(() => l());
                  }
                } else {
                  _statusMap[action] = status;
                }
                actions = List.of(_statusMap.keys, growable: false)
                  ..sort((a, b) {
                    if (_statusMap[a] == _statusMap[b]) {
                      return a.id.compareTo(b.id);
                    }
                    return _order[_statusMap[a].runtimeType]! - _order[_statusMap[b].runtimeType]!;
                  });
                if (mounted) {
                  setState(() {});
                }
              }
            }, fireImmediately: true);
          }
        }
        last = state.actions;
      }
      if (mounted) {
        setState(() {});
      }
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    removeListenerCallback();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, i) {
          if (i == 0) {
            return Builder(
                key: const ValueKey('heading'),
                builder: (context) {
                  final paused = context.select<PhylumActionQueueState, bool>((state) => state.paused);
                  return ListTile(
                      dense: true,
                      title: Text(
                        'Pending Updates (${actions.length})',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      leading: (kDebugMode && !paused)
                          ? IconButton(
                              icon: Icon(Icons.pause),
                              onPressed: () {
                                context.read<PhylumActionQueue>().pause();
                              },
                            )
                          : null);
                });
          }
          return ActionView(action: actions[i - 1]);
        },
        childCount: actions.length + 1,
      ),
    );
  }
}
