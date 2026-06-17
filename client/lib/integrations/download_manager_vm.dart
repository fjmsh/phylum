import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/util/time.dart';
import 'package:provider/provider.dart';

Future<bool> downloadResource(
  BuildContext context,
  Resource r, {
  ResourceVersion? version,
}) async {
  await context.read<DownloadManager>().downloadResource(
    context.read(),
    r,
    version: version,
  );
  return true;
}

class DownloadManager with ChangeNotifier {
  final _downloader = FileDownloader();
  final Map<String, DownloadTaskStatusNotifier> _tasks = {};
  Iterable<DownloadTaskStatusNotifier> get tasks => _tasks.values;

  DownloadManager() : super() {
    _downloader.configure(
      globalConfig: (Config.runInForeground, Config.always),
    );
    _downloader.configureNotification(
      running: TaskNotification("Downloading", "File: {filename}"),
      paused: TaskNotification("Download Paused", "File: {filename}"),
      error: TaskNotification("Download Error", "File: {filename}"),
      complete: TaskNotification("Download Complete", "File: {filename}"),
      progressBar: true,
    );
    _downloader.registerCallbacks(
      taskNotificationTapCallback: (task, notificationType) async {
        if (task.group == 'immediate') return;
        if (notificationType == NotificationType.complete) {
          final path = await _downloader.pathInSharedStorage(
            await task.filePath(),
            SharedStorage.downloads,
          );

          if (path != null) {
            _downloader.openFile(filePath: path);
          }
        }
      },
      taskProgressCallback: (update) {
        final task = update.task;
        if (task.group == 'immediate') return;
        if (task is DownloadTask) {
          if (!_tasks.containsKey(task.taskId)) {
            _tasks[task.taskId] = DownloadTaskStatusNotifier(
              task: task,
              status: TaskStatus.running,
              progress: update,
            );
            notifyListeners();
          } else {
            _tasks[task.taskId]!.progress = update;
          }
        }
      },
      taskStatusCallback: (update) {
        final task = update.task;
        if (task.group == 'immediate') return;
        if (task is DownloadTask) {
          if (update.status == TaskStatus.complete) {
            _downloader.moveToSharedStorage(
              task,
              SharedStorage.downloads,
              mimeType: task.metaData,
            );
          }
          if (!_tasks.containsKey(task.taskId)) {
            _tasks[task.taskId] = DownloadTaskStatusNotifier(
              task: task,
              status: update.status,
            );
            notifyListeners();
          } else {
            _tasks[task.taskId]!.status = update.status;
          }
        }
      },
    );
    _downloader.start();
  }

  Future<void> downloadResource(
    PhylumAccount account,
    Resource r, {
    ResourceVersion? version,
  }) async {
    await _downloader.ready;
    if (Platform.isAndroid || Platform.isAndroid) {
      await Permission.notification.request();
    }
    final uri = account.apiClient.createUriBuilder(
      '/api/v1/fs/contents/${r.id}:',
    );
    if (version != null) {
      uri.queryParameters['version'] = version.id;
    }
    final v = version ?? await account.db.latestVersion(r.id).getSingleOrNull();
    final mimeType =
        v?.mimeType ??
        MimeTypeResolver().lookup(r.name) ??
        'application/octet-stream';
    final task = DownloadTask(
      url: uri.toString(),
      filename: version == null
          ? r.name
          : '${r.name}-${version.created.formatNumericDateTime()}',
      displayName: r.name,
      headers: account.apiClient.requestHeaders,
      updates: Updates.statusAndProgress,
      retries: 5,
      allowPause: true,
      metaData: mimeType,
    );

    _tasks[task.taskId] = DownloadTaskStatusNotifier(task: task);

    await _downloader.enqueue(task);

    notifyListeners();
  }
}

class DownloadTaskStatusNotifier with ChangeNotifier {
  final Task task;

  TaskStatus _status = TaskStatus.enqueued;
  TaskStatus get status => _status;
  set status(TaskStatus status) {
    _status = status;
    notifyListeners();
  }

  late TaskProgressUpdate _progress = TaskProgressUpdate(task, 0);
  TaskProgressUpdate get progress => _progress;
  set progress(TaskProgressUpdate progress) {
    _progress = progress;
    notifyListeners();
  }

  DownloadTaskStatusNotifier({
    required this.task,
    TaskStatus? status,
    TaskProgressUpdate? progress,
  }) : _status = status ?? TaskStatus.enqueued,
       _progress = progress ?? TaskProgressUpdate(task, 0);
}
