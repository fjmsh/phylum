import 'package:flutter/material.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';
import 'package:provider/provider.dart';

class ActionQueueSliver extends StatelessWidget {
  const ActionQueueSliver({super.key});

  @override
  Widget build(BuildContext context) {
    final actions = context.select<PhylumActionQueueState, List<QueuedAction<PhylumAccount>>>((state) => state.actions);
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, i) {
          if (i == 0) {
            return const ListTile(dense: true, title: Text('Actions'));
          }
          return ActionView(action: actions[i - 1]);
        },
        childCount: actions.length + 1,
      ),
    );
  }
}

class ActionView extends StatelessWidget {
  final QueuedAction<PhylumAccount> action;
  ActionView({required this.action}) : super(key: ValueKey(action.id));

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: action.statusNotifier.stream,
      initialData: action.status,
      builder: (context, snapshot) => buildTile(context, snapshot.data!),
    );
  }

  Widget buildTile(BuildContext context, ActionStatus status) {
    return switch (status) {
      ActionStatusWaiting() || ActionStatusReady() || ActionStatusSubmitting() || ActionStatusDone() => buildSimpleInfoTile(context, status),
      ActionStatusError(error: final error) => buildErrorInfoTile(context, error),
    };
  }

  Widget buildSimpleInfoTile(BuildContext context, ActionStatus status) {
    final account = context.read<PhylumAccount>();
    return ListTile(
      title: Text(action.action.generateDescription(account)),
      subtitle: Text(status.toString()),
      trailing: status is ActionStatusSubmitting
          ? null
          : IconButton(onPressed: () => context.read<PhylumActionQueue>().deleteAction(action.id), icon: const Icon(Icons.delete)),
    );
  }

  Widget buildErrorInfoTile(BuildContext context, ApiResult error) {
    final account = context.read<PhylumAccount>();
    String description = error.description;
    if (error is PhylumApiErrorResponse) {
      if (error.code == "name_conflict") {
        description = 'Error: Another resource with this name already exists on the server.';
      }
    }
    return ListTile(
      title: Text(action.action.generateDescription(account), overflow: TextOverflow.fade),
      subtitle: Text(description),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => context.read<PhylumActionQueue>().retryAction(action.id)),
          IconButton(icon: const Icon(Icons.delete), onPressed: () => context.read<PhylumActionQueue>().deleteAction(action.id)),
        ],
      ),
    );
  }
}
