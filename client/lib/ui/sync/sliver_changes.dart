import 'package:flutter/material.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/actions/action_resource_upload.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';
import 'package:provider/provider.dart';

import 'action_view.dart';

class SliverUpdates extends StatelessWidget {
  const SliverUpdates({super.key});

  @override
  Widget build(BuildContext context) {
    final actions = context.select<PhylumActionQueueState, List<QueuedAction<PhylumAccount>>>((state) => state.actions);
    final updates = actions.where((action) => action.action is! ResourceUploadAction).toList(growable: false);

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, i) {
          if (i == 0) {
            return const ListTile(dense: true, title: Text('Updates'));
          }
          return ActionView(action: updates[i - 1]);
        },
        childCount: updates.isEmpty ? 0 : updates.length + 1,
      ),
    );
  }
}
