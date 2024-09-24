import 'package:flutter/material.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';
import 'package:provider/provider.dart';

class ActionQueueList extends StatelessWidget {
  const ActionQueueList({super.key});

  @override
  Widget build(BuildContext context) {
    final queue = context.select<PhylumActionQueueState, Iterable<PhylumAction>>((state) => state.actions.keys).toList(growable: false);
    return ListView.builder(
      shrinkWrap: true,
      itemCount: queue.length,
      itemBuilder: (context, i) {
        return ActionView(action: queue[i]);
      },
    );
  }
}

class ActionView extends StatelessWidget {
  final PhylumAction action;
  ActionView({required this.action}) : super(key: ValueKey(action.key));

  @override
  Widget build(BuildContext context) {
    final state = context.select<PhylumActionQueueState, ActionStatus>((state) => state.actions[action]!);
    return switch (state) {
      ActionStatusWaiting() || ActionStatusReady() || ActionStatusSubmitting() || ActionStatusDone() => buildSimpleInfoTile(context, state),
      ActionStatusError(error: final error) => buildErrorInfoTile(context, error),
    };
  }

  Widget buildSimpleInfoTile(BuildContext context, ActionStatus status) {
    final account = context.read<PhylumAccount>();
    return ListTile(
      title: Text(action.generateDescription(account)),
      subtitle: Text(status.toString()),
      trailing: status is ActionStatusSubmitting
          ? null
          : IconButton(onPressed: () => context.read<ApiActionQueue>().deleteAction(action), icon: const Icon(Icons.delete)),
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
      title: Text(action.generateDescription(account), overflow: TextOverflow.fade),
      subtitle: Text(description),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => context.read<PhylumActionQueue>().retryAction(action)),
          IconButton(icon: const Icon(Icons.delete), onPressed: () => context.read<PhylumActionQueue>().deleteAction(action)),
        ],
      ),
    );
  }
}
