import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/material.dart';
import 'package:phylum/integrations/download_manager_vm.dart';
import 'package:provider/provider.dart';

class DownloadsList extends StatelessWidget {
  const DownloadsList({super.key});

  @override
  Widget build(BuildContext context) {
    final tasks = context.watch<DownloadManager>().tasks.toList(growable: false);
    return ListView.builder(
      itemBuilder: (context, i) => _DownloadTaskView(notifier: tasks[tasks.length - i - 1]),
      itemCount: tasks.length,
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
