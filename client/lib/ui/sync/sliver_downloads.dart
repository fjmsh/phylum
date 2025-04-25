import 'dart:math';

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/material.dart';
import 'package:phylum/integrations/download_manager.dart';
import 'package:provider/provider.dart';

const _showedDownloads = 3;

class DownloadsSliver extends StatefulWidget {
  const DownloadsSliver({super.key});

  @override
  State<DownloadsSliver> createState() => _DownloadsSliverState();
}

class _DownloadsSliverState extends State<DownloadsSliver> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final allTasks = context.watch<DownloadManager>().tasks.toList(growable: false);
    final tasks = allTasks.sublist(max(allTasks.length - _showedDownloads, 0)).toList(growable: false);
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, i) {
          if (i == 0) {
            return const ListTile(dense: true, title: Text('Downloads'));
          }
          if (i > tasks.length) {
            return Padding(
              padding: const EdgeInsets.all(12.0),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: Text('View All (${allTasks.length - _showedDownloads} More)'),
                ),
              ),
            );
          }
          return _DownloadTaskView(notifier: tasks[tasks.length - i]);
        },
        childCount: tasks.length + 1 + (allTasks.length >= _showedDownloads ? 1 : 0),
      ),
    );
  }
}

class _DownloadTaskView extends StatefulWidget {
  final DownloadTaskStatusNotifier notifier;

  _DownloadTaskView({required this.notifier}) : super(key: ValueKey(notifier.task.taskId));

  @override
  State<_DownloadTaskView> createState() => _DownloadTaskViewState();
}

class _DownloadTaskViewState extends State<_DownloadTaskView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.notifier,
      builder: (context, child) {
        return ListTile(
          title: Text(widget.notifier.task.displayName),
          subtitle: buildSubtitle(),
        );
      },
    );
  }

  Widget buildSubtitle() {
    return switch (widget.notifier.status) {
      TaskStatus.enqueued => const LinearProgressIndicator(value: null),
      TaskStatus.running => LinearProgressIndicator(
          value: widget.notifier.progress.progress < 1 ? widget.notifier.progress.progress : null),
      TaskStatus.canceled => const Text('Canceled'),
      TaskStatus.complete => const Text('Complete'),
      TaskStatus.notFound => const Text('Not Found'),
      TaskStatus.failed => const Text('Failed'),
      TaskStatus.waitingToRetry => const Text('Waiting to Retry'),
      TaskStatus.paused => const Text('Paused'),
    };
  }
}
