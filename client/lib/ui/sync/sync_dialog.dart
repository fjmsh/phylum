import 'package:flutter/material.dart';
import 'package:phylum/integrations/download_manager.dart';
import 'package:phylum/ui/sync/action_queue_list.dart';
import 'package:provider/provider.dart';

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
        slivers: [DownloadsSliver(), ActionQueueSliver()],
      );
}

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
    final running = context.select<DownloadManagerState, List<DownloadTask>>((state) => state.running);
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, i) {
          if (i == 0) {
            return const ListTile(dense: true, title: Text('Downloads'));
          }
          return _DownloadTaskView(task: running[running.length - i]);
        },
        childCount: running.length + 1,
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
