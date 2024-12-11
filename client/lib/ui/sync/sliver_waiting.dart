import 'package:flutter/material.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/app/action_queue_status_notifier.dart';
import 'package:provider/provider.dart';

import 'action_view.dart';

class SubmittingSliver extends StatelessWidget {
  const SubmittingSliver({super.key});

  @override
  Widget build(BuildContext context) {
    final actions = context.select<ActionQueueStatusNotifier, List<QueuedAction<PhylumAccount>>>((state) {
      return state.waitingActions;
    });

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, i) {
          if (i == 0) {
            return const ListTile(dense: true, title: Text('Waiting'));
          }
          return ActionView(action: actions[i - 1]);
        },
        childCount: actions.isEmpty ? 0 : actions.length + 1,
      ),
    );
  }
}
