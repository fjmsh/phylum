import 'package:flutter/material.dart';
import 'package:phylum/libphylum/actions/action_resource_upload.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';
import 'package:provider/provider.dart';

import 'action_view.dart';

class UploadsSliver extends StatelessWidget {
  const UploadsSliver({super.key});

  @override
  Widget build(BuildContext context) {
    final actions = context.select<PhylumActionQueueState, List<PhylumAction>>((state) => state.actions);
    final uploads = actions.whereType<ResourceUploadAction>().toList(growable: false);

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, i) {
          if (i == 0) {
            return const ListTile(dense: true, title: Text('Uploads'));
          }
          return ActionView(action: uploads[i - 1]);
        },
        childCount: uploads.isEmpty ? 0 : uploads.length + 1,
      ),
    );
  }
}
