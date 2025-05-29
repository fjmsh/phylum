import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/material.dart';
import 'package:phylum/integrations/download_manager_vm.dart';
import 'package:phylum/ui/downloads/downloads_dialog.dart';
import 'package:provider/provider.dart';

class DownloadButton extends StatefulWidget {
  const DownloadButton({super.key});

  @override
  State<DownloadButton> createState() => _DownloadButtonState();
}

class _DownloadButtonState extends State<DownloadButton> {
  final ongoing = <DownloadTaskStatusNotifier, Function()>{};
  late final DownloadManager _downloadManager;

  @override
  void initState() {
    super.initState();
    _downloadManager = context.read<DownloadManager>();
    _downloadManager.addListener(_onDownloadManagerChanged);
    _onDownloadManagerChanged();
  }

  void _onDownloadManagerChanged() {
    for (final task in _downloadManager.tasks) {
      if (!ongoing.containsKey(task)) {
        void listener() {
          if (task.status.isFinalState) {
            task.removeListener(ongoing.remove(task)!);
          }
          setState(() {});
        }

        ongoing[task] = listener;
        task.addListener(listener);
        listener();
      }
    }
  }

  @override
  void dispose() {
    _downloadManager.removeListener(_onDownloadManagerChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    int total = 0;
    var received = 0.0;
    for (final status in ongoing.keys) {
      if (status.status == TaskStatus.running) {
        if (status.progress.hasExpectedFileSize) {
          total += status.progress.expectedFileSize;
          received += status.progress.expectedFileSize * status.progress.progress;
        }
      }
    }
    return ListTile(
      leading: ongoing.isEmpty ? const Icon(Icons.download) : const Icon(Icons.downloading),
      title: ongoing.isEmpty ? const Text('Downloads') : Text('Downloading ${ongoing.length} files'),
      subtitle: ongoing.isEmpty
          ? null
          : LinearProgressIndicator(
              value: total == 0 ? null : (received / total),
            ),
      onTap: () {
        Scaffold.maybeOf(context)?.closeDrawer();
        DownloadsDialog.show(context);
      },
    );
  }
}
