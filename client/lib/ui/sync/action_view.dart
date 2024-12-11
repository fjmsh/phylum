import 'package:flutter/material.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';
import 'package:provider/provider.dart';

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
      ActionStatusWaiting _ || ActionStatusReady _ || ActionStatusDone _ => buildSimpleInfoTile(context, status),
      ActionStatusUploading(done: int done, length: int length) => buildProgressTile(context, done, length),
      ActionStatusError(error: final error) => buildErrorInfoTile(context, error),
    };
  }

  Widget buildSimpleInfoTile(BuildContext context, ActionStatus status) {
    final account = context.read<PhylumAccount>();
    return ListTile(
      title: Text(action.action.generateDescription(account)),
      subtitle: Text(status.toString()),
      trailing: IconButton(onPressed: () => context.read<PhylumActionQueue>().deleteAction(action.id), icon: const Icon(Icons.delete)),
    );
  }

  Widget buildProgressTile(BuildContext context, int done, int total) {
    final account = context.read<PhylumAccount>();
    return ListTile(
        title: Text(action.action.generateDescription(account)),
        subtitle: LinearProgressIndicator(
          value: total == 0 ? null : (done * 1.0 / total),
        ));
  }

  Widget buildErrorInfoTile(BuildContext context, ApiResult error) {
    final account = context.read<PhylumAccount>();
    String description = error.description;
    if (error is PhylumApiErrorResponse) {
      if (error.code == "resource_name_conflict") {
        description = 'Error: Another resource with this name already exists on the server.';
      }
    }
    return ListTile(
      title: Text(action.action.generateDescription(account), overflow: TextOverflow.fade),
      subtitle: Text(description),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(icon: const Icon(Icons.refresh), tooltip: 'Retry', onPressed: () => context.read<PhylumActionQueue>().retryAction(action.id)),
          IconButton(icon: const Icon(Icons.block), tooltip: 'Delete', onPressed: () => context.read<PhylumActionQueue>().deleteAction(action.id)),
        ],
      ),
    );
  }
}
