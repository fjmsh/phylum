import 'package:flutter/material.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/actions/action_resource_bind.dart';
import 'package:phylum/libphylum/name_conflict.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';
import 'package:phylum/libphylum/responses/responses.dart';
import 'package:phylum/util/dialogs.dart';
import 'package:provider/provider.dart';

class ActionView extends StatelessWidget {
  final PhylumAction action;
  ActionView({required this.action}) : super(key: ValueKey(action.id));

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: action.statusNotifier.stream,
      initialData: action.status,
      builder: (context, snapshot) => buildTile(context, action, snapshot.data!),
    );
  }

  Widget buildTile(BuildContext context, PhylumAction action, ActionStatus status) {
    return switch (status) {
      ActionStatusWaiting _ || ActionStatusReady _ || ActionStatusDone _ => buildSimpleInfoTile(context, status),
      ActionStatusUploading(done: int done, length: int length) => buildProgressTile(context, done, length),
      ActionStatusError(error: final error) => buildErrorInfoTile(context, action, error),
    };
  }

  Widget buildSimpleInfoTile(BuildContext context, ActionStatus status) {
    return ListTile(
      title: Text(action.description),
      subtitle: Text(status.toString()),
      trailing: IconButton(
        onPressed: () => context.read<PhylumActionQueue>().deleteAction(action),
        icon: const Icon(Icons.delete),
      ),
    );
  }

  Widget buildProgressTile(BuildContext context, int done, int total) {
    return ListTile(
        title: Text(action.description),
        subtitle: LinearProgressIndicator(
          value: total == 0 ? null : (done * 1.0 / total),
        ));
  }

  Widget buildErrorInfoTile(BuildContext context, PhylumAction action, ApiResult error) {
    final showRenameOptions = error is PhylumApiErrorResponse &&
        (error.code == "resource_name_conflict" || error.code == "resource_name_invalid");
    return ListTile(
      title: Text(action.description, overflow: TextOverflow.fade),
      subtitle: Text(error.description),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showRenameOptions)
            IconButton(
              icon: const Icon(Icons.warning),
              tooltip: 'Overwrite',
              onPressed: () async {
                if (action is! ResourceBindAction) return;
                action.updateConflictResolution(nameConflictOverwrite);
              },
            ),
          if (showRenameOptions)
            IconButton(
              icon: const Icon(Icons.healing),
              tooltip: 'Auto Rename',
              onPressed: () async {
                if (action is! ResourceBindAction) return;
                action.updateConflictResolution(nameConflictRename);
              },
            ),
          if (showRenameOptions)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Rename',
              onPressed: () async {
                if (action is! ResourceBindAction) return;
                final preset = action.resourceName;
                final name = await showInputDialog(context,
                    title: 'Edit Name',
                    preset: preset,
                    capitalization: TextCapitalization.words,
                    validate: (name) => name.trim().isNotEmpty);
                if (name == null || !context.mounted) return;
                action.updateResourceName(name);
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Retry',
            onPressed: () => context.read<PhylumActionQueue>().retryAction(action),
          ),
          IconButton(
            icon: const Icon(Icons.block),
            tooltip: 'Delete',
            onPressed: () => context.read<PhylumActionQueue>().deleteAction(action),
          ),
        ],
      ),
    );
  }
}
