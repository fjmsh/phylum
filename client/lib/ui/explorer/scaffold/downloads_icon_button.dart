import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/material.dart';
import 'package:phylum/integrations/download_manager_vm.dart';
import 'package:phylum/ui/app/routing/router.dart';
import 'package:phylum/ui/settings/downloads/downloads_settings.dart';
import 'package:provider/provider.dart';

class DownloadsIconButton extends StatefulWidget {
  const DownloadsIconButton({super.key});

  @override
  State<DownloadsIconButton> createState() => _DownloadsIconButtonState();
}

class _DownloadsIconButtonState extends State<DownloadsIconButton> {
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
          received +=
              status.progress.expectedFileSize * status.progress.progress;
        }
      }
    }
    return IconButton(
      icon: Stack(
        alignment: Alignment.center,
        children: [
          ongoing.isEmpty
              ? const Icon(Icons.download)
              : const Icon(Icons.downloading),
          if (ongoing.isNotEmpty)
            CircularProgressIndicator(
              strokeWidth: 1.8,
              value: total == 0 ? null : (received / total),
            ),
        ],
      ),
      tooltip: ongoing.isEmpty
          ? 'Downloads'
          : 'Downloading ${ongoing.length} files',
      onPressed: () {
        Scaffold.maybeOf(context)?.closeDrawer();
        context.read<PhylumRouterDelegate>().go(
          SettingsRoute(selected: const DownloadsSettings()),
        );
      },
    );
  }
}
