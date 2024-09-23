import 'package:flutter/material.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';
import 'package:provider/provider.dart';

class ActionQueueList extends StatelessWidget {
  const ActionQueueList({super.key});

  @override
  Widget build(BuildContext context) {
    final queue = context.select<PhylumApiActionQueueState, Iterable<PhylumApiAction>>((state) => state.actions.keys).toList(growable: false);
    return ListView.builder(
      shrinkWrap: true,
      itemCount: queue.length,
      itemBuilder: (context, i) {
        print(queue[i]);
        return ActionView(action: queue[i]);
      },
    );
  }
}

class ActionView extends StatelessWidget {
  final PhylumApiAction action;
  ActionView({required this.action}) : super(key: ValueKey(action.key));

  @override
  Widget build(BuildContext context) {
    final state = context.select<PhylumApiActionQueueState, PhylumApiActionStatus>((state) => state.actions[action]!);
    return switch (state) {
      ActionStateWaiting() || ActionStateReady() || ActionStateSubmitting() || ActionStateDone() => buildSimpleInfoTile(context, state),
      PhylumApiActionStatusError(error: final error) => buildErrorInfoTile(context, error),
    };
  }

  Widget buildSimpleInfoTile(BuildContext context, ActionState status) {
    final account = context.read<PhylumAccount>();
    return ListTile(
      title: Text(action.generateDescription(account)),
      subtitle: Text(status.toString()),
      trailing: status is ActionStateSubmitting
          ? null
          : IconButton(onPressed: () => context.read<ApiActionQueue>().deleteAction(action), icon: const Icon(Icons.delete)),
    );
  }

  Widget buildErrorInfoTile(BuildContext context, ApiResult<PhylumApiResponse, PhylumApiErrorResponse> error) {
    final account = context.read<PhylumAccount>();
    String description = error.description;
    if (error is ApiErrorResponse<PhylumApiResponse, PhylumApiErrorResponse>) {
      final err = error.err;
      if (err.code == "name_conflict") {
        description = 'Error: Another resource with this name already exists on the server.';
      }
    }
    return ListTile(
      title: Text(action.generateDescription(account), overflow: TextOverflow.fade),
      subtitle: Text(description),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => context.read<PhylumApiActionQueue>().retryAction(action)),
          IconButton(icon: const Icon(Icons.delete), onPressed: () => context.read<PhylumApiActionQueue>().deleteAction(action)),
        ],
      ),
    );
  }
}
