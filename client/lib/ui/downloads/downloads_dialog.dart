import 'package:flutter/material.dart';
import 'package:phylum/ui/downloads/downloads_list.dart';

class DownloadsDialog extends StatelessWidget {
  const DownloadsDialog({super.key});

  static void show(BuildContext context) {
    showDialog(context: context, builder: (context) => const DownloadsDialog());
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    if (size.width < 600) {
      return Scaffold(
          appBar: AppBar(
            title: const Text('Downloads'),
          ),
          body: const DownloadsList());
    } else {
      return Center(
        child: SizedBox(
          width: 800,
          child: Card(
            margin: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                AppBar(
                  title: const Text('Downloads'),
                  leading: const CloseButton(),
                  backgroundColor: Colors.transparent,
                ),
                Expanded(child: const DownloadsList()),
              ],
            ),
          ),
        ),
      );
    }
  }
}
