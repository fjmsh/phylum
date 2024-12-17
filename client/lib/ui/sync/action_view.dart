import 'package:flutter/material.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/actions/action_resource_bind.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';
import 'package:phylum/util/dialogs.dart';
import 'package:provider/provider.dart';

class ActionView extends StatelessWidget {
  final QueuedAction<PhylumAccount> action;
  ActionView({required this.action}) : super(key: ValueKey(action.id));

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: action.statusNotifier.stream,
      initialData: action.status,
      builder: (context, snapshot) => buildTile(context, action, snapshot.data!),
    );
  }

  Widget buildTile(BuildContext context, QueuedAction<PhylumAccount> action, ActionStatus status) {
    return switch (status) {
      ActionStatusWaiting _ || ActionStatusReady _ || ActionStatusDone _ => buildSimpleInfoTile(context, status),
      ActionStatusUploading(done: int done, length: int length) => buildProgressTile(context, done, length),
      ActionStatusError(error: final error) => buildErrorInfoTile(context, action, error),
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

  Widget buildErrorInfoTile(BuildContext context, QueuedAction<PhylumAccount> action, ApiResult error) {
    final account = context.read<PhylumAccount>();
    final showRenameOptions = error is PhylumApiErrorResponse && (error.code == "resource_name_conflict" || error.code == "resource_name_invalid");
    return ListTile(
      title: Text(action.action.generateDescription(account), overflow: TextOverflow.fade),
      subtitle: Text(error.description),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showRenameOptions)
            IconButton(
                icon: const Icon(Icons.edit),
                tooltip: 'Rename',
                onPressed: () async {
                  final preset = (action.action is ResourceBindAction) ? (action.action as ResourceBindAction).resourceName : null;
                  final name = await showInputDialog(context,
                      title: 'Edit Name', preset: preset, capitalization: TextCapitalization.words, validate: (name) => name.trim().isNotEmpty);
                  if (name == null) return;
                }),
          IconButton(icon: const Icon(Icons.refresh), tooltip: 'Retry', onPressed: () => context.read<PhylumActionQueue>().retryAction(action.id)),
          IconButton(icon: const Icon(Icons.block), tooltip: 'Delete', onPressed: () => context.read<PhylumActionQueue>().deleteAction(action.id)),
        ],
      ),
    );
  }
}
