import 'package:flutter/material.dart';
import 'package:phylum/ui/app/routing/router.dart';
import 'package:phylum/ui/explorer/scaffold/sync/sync_status_notifier.dart';
import 'package:phylum/ui/settings/sync/sync_settings.dart';
import 'package:provider/provider.dart';

class SyncStatusButton extends StatelessWidget {
  const SyncStatusButton({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.select<SyncStatusNotifier, SyncStatus>(
      (notifier) => notifier.status,
    );
    return IconButton(
      icon: Icon(state.icon),
      onPressed: () {
        Scaffold.maybeOf(context)?.closeDrawer();
        context.read<PhylumRouterDelegate>().go(
          SettingsRoute(selected: SyncSettings()),
        );
      },
    );
  }
}
