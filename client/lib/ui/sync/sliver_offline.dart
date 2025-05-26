import 'package:flutter/material.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';
import 'package:provider/provider.dart';

class PausedOfflineSliver extends StatelessWidget {
  const PausedOfflineSliver({super.key});

  @override
  Widget build(BuildContext context) {
    final paused = context.select<PhylumActionQueueState, bool>((state) => state.paused);
    final unreachable = context.select<PhylumActionQueueState, bool>((state) => state.unreachable);

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, i) {
          if (paused) {
            return ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Sync Paused'),
              subtitle: const Text('Tap to resume'),
              onTap: () {
                context.read<PhylumActionQueue>().resume();
              },
            );
          }
          return ListTile(
            leading: const Icon(Icons.refresh),
            title: const Text('Server Unreachable'),
            subtitle: const Text('Tap to retry'),
            onTap: () {
              context.read<PhylumActionQueue>().retry();
            },
          );
        },
        childCount: paused || unreachable ? 1 : 0,
      ),
    );
  }
}
