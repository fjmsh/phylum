import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:offtheline/offtheline.dart';
import 'package:path/path.dart' as p;
import 'package:phylum/integrations/directories.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';
import 'package:phylum/libphylum/requests/resource_contents_request.dart';
import 'package:state_notifier/state_notifier.dart';

const _keyDownloadTaskId = 'downloadTaskId';

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
    int id = account.getPersisted<int>(_keyDownloadTaskId) ?? 1;
    await account.persist(_keyDownloadTaskId, id + 1);
    final task = DownloadTask(id: id, resourceId: r.id, resourceName: r.name, expectedSize: r.size);

    RemoveListener? remove;
    remove = task._statusNotifier.addListener((status) {
      if (status is DownloadStatusError || status is DownloadStatusFinished) {
        Future.microtask(() {
          remove?.call();
          final running = List.of(state.running)..remove(task);
          state = DownloadManagerState(running, [...state.finished, task]);
        });
      }
    });

    state = state.copyWith(running: [...state.running, task]);
    try {
      task.status = const DownloadStatusStarting();
      final response = await account.apiClient.dispatchRequestRaw(ResourceContentsRequest(r.id));
      if (response.statusCode < 200 || response.statusCode > 300) {
        final error = PhylumApiErrorResponse.fromResponseString(await response.bodyString());
        task.status = DownloadStatusError(error.message);
        return;
      }
      final output = _createDownloadFile(PhylumDirectories.instance.downloads!, r.name);
      if (output == null) {
        task.status = const DownloadStatusError('Unable to open output file');
        return;
      }
      final sink = output.openWrite();

      final length = response.contentLength ?? r.size;
      int received = 0;
      final stream = response.stream.map((s) {
        received += s.length;
        task.status = DownloadStatusRunning(received, length);
        return s;
      });
      sink.addStream(stream).onError((err, _) {
        debugPrint(err.toString());
        sink.close();
        task.status = DownloadStatusError(err.toString());
        output.deleteSync();
      }).whenComplete(() => task.status = DownloadStatusFinished(output.path));
    } on SocketException {
      task.status = const DownloadStatusError('Cannot reach server');
    } catch (e) {
      task.status = DownloadStatusError('Unknown Error - $e');
    }
  }

  File? _createDownloadFile(Directory dir, String name) {
    final file = File(p.join(dir.path, name));
    if (!file.existsSync()) {
      file.createSync();
      return file;
    }

    final basename = p.basenameWithoutExtension(name);
    final ext = p.extension(name);
    for (int i = 1; i < 1000; i++) {
      final file = File(p.join(dir.path, '$basename ($i)$ext'));
      if (!file.existsSync()) {
        file.createSync();
        return file;
      }
    }

    return null;
  }
}

class DownloadStatusNotifier extends StateNotifier<DownloadStatus> {
  DownloadStatus get value => state;
  set value(DownloadStatus status) => state = status;

  DownloadStatusNotifier() : super(const DownloadStatusWaiting());
}

class DownloadTask {
  final int id;
  final String resourceId;
  final String resourceName;
  final int expectedSize;
  late final DownloadStatusNotifier _statusNotifier;
  StateNotifier<DownloadStatus> get statusNotifier => _statusNotifier;

  DownloadStatus get status => _statusNotifier.value;
  set status(DownloadStatus status) => _statusNotifier.value = status;

  DownloadTask({
    required this.id,
    required this.resourceId,
    required this.resourceName,
    required this.expectedSize,
  }) : _statusNotifier = DownloadStatusNotifier();
}

sealed class DownloadStatus {
  const DownloadStatus();
}

class DownloadStatusWaiting extends DownloadStatus {
  const DownloadStatusWaiting();

  @override
  String toString() => 'Waiting';
}

class DownloadStatusStarting extends DownloadStatus {
  const DownloadStatusStarting();

  @override
  String toString() => 'Starting';
}

class DownloadStatusRunning extends DownloadStatus {
  final int received;
  final int size;

  const DownloadStatusRunning(this.received, this.size);

  @override
  String toString() => 'Running: $received / $size (${received / size * 100} %)';
}

class DownloadStatusFinished extends DownloadStatus {
  final String path;

  const DownloadStatusFinished(this.path);

  @override
  String toString() => 'Finished: $path';
}

class DownloadStatusError extends DownloadStatus {
  final String error;

  const DownloadStatusError(this.error);

  @override
  String toString() => 'Error: $error';
}
