import 'package:flutter/material.dart';
import 'package:phylum/ui/sync/sliver_submitting.dart';
import 'package:phylum/ui/sync/sliver_offline.dart';
import 'package:phylum/ui/sync/sliver_uploads.dart';
import 'package:phylum/ui/sync/sliver_downloads.dart';

import 'sliver_errors.dart';

class SyncDialog extends StatelessWidget {
  const SyncDialog({super.key});

  static void show(BuildContext context) {
    showDialog(context: context, builder: (context) => const SyncDialog());
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    if (size.width < 600) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Server Status'),
        ),
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
                AppBar(title: const Text('Server Status'), leading: const CloseButton(), backgroundColor: Colors.transparent),
                Expanded(child: buildContents(context)),
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget buildContents(BuildContext context) => const CustomScrollView(
        slivers: [OfflineSliver(), DownloadsSliver(), ErrorsSliver(), UploadsSliver(), SubmittingSliver()],
      );
}
