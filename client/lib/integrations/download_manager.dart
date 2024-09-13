import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:offtheline/offtheline.dart';
import 'package:path/path.dart' as p;
import 'package:phylum/integrations/directories.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/requests/resource_contents_request.dart';
import 'package:state_notifier/state_notifier.dart';

class DownloadManagerState {
  final List<DownloadTask> running;
  final List<DownloadTask> finished;

  const DownloadManagerState([this.running = const [], this.finished = const []]);

  DownloadManagerState copyWith({List<DownloadTask>? running, List<DownloadTask>? finished}) {
    return DownloadManagerState(running ?? this.running, finished ?? this.finished);
  }
}

class DownloadManager extends StateNotifier<DownloadManagerState> {
  final PhylumAccount account;

  DownloadManager(this.account) : super(const DownloadManagerState());

  Future<void> downloadResource(Resource r) async {
    final task = DownloadTask(resourceId: r.id, resourceName: r.name, expectedSize: r.size);
    l() {
      final status = task._status.value;
      if (status is DownloadStatusError || status is DownloadStatusFinished) {
        task._status.removeListener(l);
        final running = List.of(state.running)..remove(task);
        state = DownloadManagerState(running, [...state.finished, task]);
      }
    }

    task._status.addListener(l);

    state = state.copyWith(running: [...state.running, task]);
    final apiResponse = await account.api.sendRequestRaw(ResourceContentsRequest(r.id));
    if (apiResponse.error != null) {
      final msg = switch (apiResponse.error) {
        const ApiClosedError() => 'Api closed',
        const ApiOfflineError() => 'Cannot reach server',
        ApiUnknownError(ex: dynamic ex) => 'Unknown Error - $ex',
        ApiRequestError(err: PhylumApiErrorResponse err) => 'Request Error - ${err.message}',
        _ => '',
      };
      task._status.value = DownloadStatusError(msg);
      return;
    } else {
      final output = _createDownloadFile(PhylumDirectories.instance.downloads!, r.name);
      if (output == null) {
        task._status.value = const DownloadStatusError('Unable to open output file');
        return;
      }
      final sink = output.openWrite();

      final httpResponse = apiResponse.result!;
      final length = httpResponse.contentLength ?? r.size;
      int received = 0;
      final stream = httpResponse.stream.map((s) {
        received += s.length;
        task._status.value = DownloadStatusRunning(received, length);
        return s;
      });
      sink.addStream(stream).then((err) {
        sink.close();
        if (err == null) {
          task._status.value = DownloadStatusFinished(output.path);
        } else {
          task._status.value = DownloadStatusError(err.toString());
          output.deleteSync();
        }
      });
    }
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
  late final ValueNotifier<DownloadStatus> _status;
  ValueListenable<DownloadStatus> get status => _status;

  DownloadTask({
    required this.resourceId,
    required this.resourceName,
    required int expectedSize,
  }) : _status = ValueNotifier(DownloadStatusRunning(0, expectedSize));
}

sealed class DownloadStatus {
  const DownloadStatus();
}

class DownloadStatusRunning extends DownloadStatus {
  final int received;
  final int total;

  const DownloadStatusRunning(this.received, this.total);

  @override
  String toString() => "Download Running: $received / $total (${received / total * 100} %)";
}

class DownloadStatusFinished extends DownloadStatus {
  final String path;

  const DownloadStatusFinished(this.path);

  @override
  String toString() => "Download Finished: $path";
}

class DownloadStatusError extends DownloadStatus {
  final String error;

  const DownloadStatusError(this.error);

  @override
  String toString() => "Download Error: $error";
}
