import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:phylum/integrations/directories.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/requests/resource_contents_request.dart';
import 'package:state_notifier/state_notifier.dart';

class DownloadManagerState {
  final List<DownloadTask> tasks;
  const DownloadManagerState([this.tasks = const []]);
}

class DownloadManager extends StateNotifier<DownloadManagerState> {
  final PhylumAccount account;

  DownloadManager(this.account) : super(const DownloadManagerState());

  void downloadResource(Resource r) async {
    final output = _createDownloadFile(PhylumDirectories.instance.downloads!, r.name);
    if (output == null) {
      return;
    }
    final task = DownloadTask(resourceId: r.id, resourceName: r.name, savePath: output.path, contentLength: r.size);
    state = DownloadManagerState([...state.tasks, task]);
    IOSink? sink;
    sink = output.openWrite();
    final response = await account.api.sendRequestRaw(ResourceContentsRequest(r.id));
    if (response == null) return;
    final length = response.contentLength ?? r.size;
    int received = 0;
    response.stream
        .map((s) {
          received += s.length;
          task._status.value = DownloadStatusRunning(received, length);
          return s;
        })
        .pipe(sink)
        .whenComplete(() => task._status.value = const DownloadStatusFinished())
        .onError((err, _) {
          task._status.value = DownloadStatusError(err.toString());
          return null;
        });

    l() {
      final status = task._status.value;
      debugPrint(status.toString());
      if (status is DownloadStatusError || status is DownloadStatusFinished) {
        task._status.removeListener(l);
      }
    }

    task._status.addListener(l);
  }

  File? _createDownloadFile(Directory dir, String name) {
    final file = File(p.join(dir.path, name));
    if (!file.existsSync()) {
      file.createSync();
      return file;
    }

    final basename = p.basename(name);
    final ext = p.extension(name);
    for (int i = 1; i < 1000; i++) {
      final file = File(p.join(dir.path, '$basename ($i).$ext'));
      if (!file.existsSync()) {
        file.createSync();
        return file;
      }
    }

    return null;
  }
}

class DownloadTask {
  final String resourceId;
  final String resourceName;
  final String savePath;
  final int contentLength;
  final ValueNotifier<DownloadStatus> _status = ValueNotifier(const DownloadStatusEnqueued());
  ValueListenable<DownloadStatus> get status => _status;

  DownloadTask({
    required this.resourceId,
    required this.resourceName,
    required this.savePath,
    required this.contentLength,
  });
}

sealed class DownloadStatus {
  const DownloadStatus();
}

class DownloadStatusEnqueued extends DownloadStatus {
  const DownloadStatusEnqueued();

  @override
  String toString() => "Download Enqueued";
}

class DownloadStatusRunning extends DownloadStatus {
  final int received;
  final int total;

  const DownloadStatusRunning(this.received, this.total);

  @override
  String toString() => "Download Running: $received / $total (${received / total * 100} %)";
}

class DownloadStatusFinished extends DownloadStatus {
  const DownloadStatusFinished();

  @override
  String toString() => "Download Finished";
}

class DownloadStatusError extends DownloadStatus {
  final String error;

  const DownloadStatusError(this.error);

  @override
  String toString() => "Download Error: $error";
}
