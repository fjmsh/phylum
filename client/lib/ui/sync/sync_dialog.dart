import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';
import 'package:phylum/ui/sync/sliver_paused_unreachable.dart';
import 'package:provider/provider.dart';

import 'sliver_actions.dart';

class SyncDialog extends StatelessWidget {
  const SyncDialog({super.key});

  static void show(BuildContext context) {
    final account = context.read<PhylumAccount>();
    showDialog(
      context: context,
      builder: (context) => MultiProvider(
        providers: [
          Provider.value(value: account),
          StateNotifierProvider<
            ApiActionQueue<PhylumAccount>,
            PhylumActionQueueState
          >.value(value: account.actionQueue),
        ],
        builder: (context, _) {
          return const SyncDialog();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    if (size.width < 600) {
      return Scaffold(
        appBar: AppBar(title: const Text('Server Sync')),
        body: buildContents(context),
      );
    } else {
      return Center(
        child: SizedBox(
          width: 800,
          child: Card(
            margin: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                AppBar(
                  title: const Text('Server Sync'),
                  leading: const CloseButton(),
                  backgroundColor: Colors.transparent,
                ),
                Expanded(child: buildContents(context)),
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget buildContents(BuildContext context) =>
      const CustomScrollView(slivers: [PausedOfflineSliver(), ActionsSliver()]);
}
