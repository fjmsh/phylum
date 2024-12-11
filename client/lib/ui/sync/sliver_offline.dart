import 'package:flutter/material.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';
import 'package:provider/provider.dart';

class OfflineSliver extends StatelessWidget {
  const OfflineSliver({super.key});

  @override
  Widget build(BuildContext context) {
    final unreachable = context.select<PhylumActionQueueState, bool>((state) => state.unreachable);

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, i) {
          return ListTile(
            leading: Icon(Icons.refresh),
            title: Text('Server Unreachable'),
            subtitle: Text('Tap to retry'),
            onTap: () {
              context.read<PhylumActionQueue>().resume();
            },
          );
        },
        childCount: unreachable ? 1 : 0,
      ),
    );
  }
}
