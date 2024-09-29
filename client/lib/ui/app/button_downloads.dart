import 'dart:async';

import 'package:flutter/material.dart';
import 'package:phylum/integrations/download_manager.dart';
import 'package:provider/provider.dart';
import 'package:state_notifier/state_notifier.dart';

class DownloadButton extends StatefulWidget {
  const DownloadButton({super.key});

  @override
  State<DownloadButton> createState() => _DownloadButtonState();
}

class _DownloadButtonState extends State<DownloadButton> {
  final listeners = <DownloadTask, RemoveListener>{};
  final lastStatus = <DownloadTask, DownloadStatus>{};
  late final StreamSubscription _subscription;
  int ongoing = 0;
  int received = 0;
  int total = 0;

  @override
  void initState() {
    super.initState();
    _subscription = context.read<DownloadManager>().stream.listen((state) {
      for (final task in state.tasks) {
        if (!listeners.containsKey(task)) {
          final status = task.status;
          if (status is! DownloadStatusFinished && status is! DownloadStatusError) {
            listeners[task] = task.statusNotifier.addListener((status) {
              int ongoing = this.ongoing;
              int received = this.received;
              int total = this.total;
              final last = lastStatus[task];
              lastStatus[task] = status;
              if (last == null) {
                ongoing++;
              } else if (last is DownloadStatusRunning) {
                received -= last.received;
                total -= last.size;
              }

              if (status is DownloadStatusRunning) {
                received += status.received;
                total += status.size;
              } else if (status is DownloadStatusFinished || status is DownloadStatusError) {
                ongoing--;
                Future.microtask(() {
                  listeners.remove(task)?.call();
                  lastStatus.remove(task);
                });
              }
              setState(() {
                this.ongoing = ongoing;
                this.received = received;
                this.total = total;
              });
            }, fireImmediately: true);
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: ongoing == 0 ? const Icon(Icons.download) : const Icon(Icons.downloading),
      title: ongoing == 0 ? const Text('Downloads') : Text('Downloading $ongoing files'),
      subtitle: ongoing == 0
          ? null
          : LinearProgressIndicator(
              value: total == 0 ? null : (received * 1.0 / total),
            ),
    );
  }
}
