import 'dart:math';

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
    final allTasks = context.select<DownloadManagerState, List<DownloadTask>>((state) => state.tasks);
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
          return _DownloadTaskView(task: tasks[tasks.length - i]);
        },
        childCount: tasks.length + 1 + (allTasks.length >= _showedDownloads ? 1 : 0),
      ),
    );
  }
}

class _DownloadTaskView extends StatefulWidget {
  final DownloadTask task;

  _DownloadTaskView({required this.task}) : super(key: ValueKey(task.id));

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
    return StreamBuilder(
      stream: widget.task.statusNotifier.stream,
      initialData: widget.task.status,
      builder: (contetx, snapshot) {
        final status = snapshot.data!;
        return ListTile(title: Text(widget.task.resourceName), subtitle: buildSubtitle(status));
      },
    );
  }

  Widget buildSubtitle(DownloadStatus status) {
    return switch (status) {
      DownloadStatusStarting _ => const LinearProgressIndicator(value: null),
      DownloadStatusRunning(received: int received, size: int size) => LinearProgressIndicator(value: (received * 1.0) / size),
      _ => Text(status.toString()),
    };
  }
}
