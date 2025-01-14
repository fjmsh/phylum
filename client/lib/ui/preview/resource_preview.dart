import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/app_shortcuts.dart';
import 'package:phylum/integrations/download_manager.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/explorer/explorer_controller.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';
import 'package:phylum/libphylum/requests/resource_contents_request.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

const maxPreviewSize = 1 * 1024 * 1024;

class ResourcePreview extends StatefulWidget {
  final Resource resource;

  ResourcePreview({required this.resource}) : super(key: ValueKey(resource.id));

  static Future<void> showPreview(BuildContext context, Resource r) async {
    context.read<PhylumAccount>().myListsRepository.markResourceAccessed(r.id);
    return showDialog(context: context, builder: (context) => ResourcePreview(resource: r));
  }

  @override
  State<ResourcePreview> createState() => _ResourcePreviewState();
}

class _ResourcePreviewState extends State<ResourcePreview> {
  late Resource _resource;
  final _focusNode = FocusNode();
  String? _error;
  Widget Function(Uint8List)? _buildPreview;

  @override
  void initState() {
    super.initState();
    _updateResource(widget.resource);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _updateResource(Resource resource) {
    this._resource = resource;
    if (resource.dir) {
      _error = 'Cannot preview directory';
    } else if (resource.contentLength > maxPreviewSize) {
      _error = 'Resource too large to preview';
    } else {
      if (resource.contentType.startsWith('image/')) {
        _buildPreview = buildImagePreview;
      }
      if (resource.contentType.startsWith('text/')) {
        _buildPreview = buildTextPreview;
      }
      if (resource.contentType == 'application/pdf') {
        _buildPreview = buildPdfPreview;
      }
      if (_buildPreview == null) {
        _error = 'Unable to preview ${resource.contentType}';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Actions(
      actions: {
        DismissIntent: CallbackAction<DismissIntent>(onInvoke: (i) {
          Navigator.of(context).pop();
        }),
        FocusLeftIntent: CallbackAction<FocusLeftIntent>(onInvoke: (FocusLeftIntent i) {
          final state = context.read<ExplorerState>();
          final index = state.resources.indexOf(_resource);
          if (index == -1) {
            return;
          }
          for (int i = index; i >= 0; i--) {
            final r = state.resources[i];
            if (!r.dir) {
              return setState(() {
                _updateResource(r);
              });
            }
          }
          return;
        }),
        FocusRightIntent: CallbackAction<FocusRightIntent>(onInvoke: (FocusRightIntent i) {
          final state = context.read<ExplorerState>();
          final index = state.resources.indexOf(_resource);
          if (index == -1) {
            return;
          }
          for (int i = index; i < state.resources.length; i++) {
            final r = state.resources[i];
            if (!r.dir) {
              return setState(() {
                _updateResource(r);
              });
            }
          }
          return;
        }),
      },
      child: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Focus(
          focusNode: _focusNode,
          autofocus: true,
          child: Scaffold(
            backgroundColor: Colors.black45,
            appBar: AppBar(
              foregroundColor: theme.colorScheme.onInverseSurface,
              leading: const CloseButton(),
              actions: [
                IconButton(
                    onPressed: (_resource.dir) ? null : () => downloadResource(), icon: const Icon(Icons.download))
              ],
              title: Text(_resource.name),
              backgroundColor: Colors.transparent,
            ),
            body: Center(
                child: _buildPreview == null
                    ? Text(_error ?? 'Unknown error', style: Theme.of(context).textTheme.bodyLarge)
                    : ResourcePreviewBuilder(
                        resource: _resource,
                        buildPreview: _buildPreview!,
                      )),
          ),
        ),
      ),
    );
  }

  Widget buildImagePreview(Uint8List data) => Image.memory(data);

  Widget buildTextPreview(Uint8List data) => Material(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextFormField(
            decoration: const InputDecoration(border: InputBorder.none),
            initialValue: String.fromCharCodes(data),
            readOnly: true,
            maxLines: 30,
          ),
        ),
      );

  Widget buildPdfPreview(Uint8List data) => PdfPreview(
        build: (_) => data,
        previewPageMargin: EdgeInsets.zero,
      );

  Future<void> downloadResource() {
    return context.read<DownloadManager>().downloadResource(_resource);
  }
}

class ResourcePreviewBuilder extends StatefulWidget {
  final Resource resource;
  final Widget Function(Uint8List data) buildPreview;

  ResourcePreviewBuilder({required this.resource, required this.buildPreview}) : super(key: ValueKey(resource.id));

  @override
  State<ResourcePreviewBuilder> createState() => _ResourcePreviewBuilderState();
}

class _ResourcePreviewBuilderState extends State<ResourcePreviewBuilder> {
  bool _downloading = false;
  String? _error;
  double? _progress;
  Uint8List? _data;

  @override
  void initState() {
    super.initState();
    _runDownloadTask();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_data != null) {
      return SizedBox(
        width: 800,
        child: widget.buildPreview(_data!),
      );
    }
    if (!_downloading) {
      return Column(
        children: [
          if (_error != null) Text(_error!),
          ElevatedButton(onPressed: _runDownloadTask, child: const Text('Retry'))
        ],
      );
    }
    return CircularProgressIndicator.adaptive(
      value: _progress,
    );
  }

  Future<void> _runDownloadTask() async {
    try {
      setState(() {
        _downloading = true;
        _error = null;
        _progress = null;
      });
      final account = context.read<PhylumAccount>();
      final response = await account.apiClient.dispatchRequestRaw(ResourceContentsRequest(widget.resource.id));
      if (response.statusCode < 200 || response.statusCode > 300) {
        final error = PhylumApiErrorResponse.fromResponseString(await response.bodyString()).message;
        _error = error;
        _downloading = false;
        if (mounted) {
          setState(() {});
        }
        return;
      }

      final expected = (response.contentLength ?? widget.resource.contentLength).toDouble();
      int received = 0;
      _progress = 0;
      if (mounted) {
        setState(() {});
      }
      final stream = _toByteStream(response.stream.map((s) {
        received += s.length;
        _progress = received / expected;
        if (mounted) {
          setState(() {});
        }
        return s;
      }));
      final data = await _toBytes(stream);
      _data = data;
      _downloading = false;
      if (mounted) {
        setState(() {});
      }
    } on SocketException {
      _error = 'Unable to reach server';
      _downloading = false;
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      _error = e.toString();
      _downloading = false;
      if (mounted) {
        setState(() {});
      }
    }
  }

  static ByteStream _toByteStream(Stream<List<int>> stream) {
    if (stream is ByteStream) return stream;
    return ByteStream(stream);
  }

  static Future<Uint8List> _toBytes(ByteStream stream) {
    var completer = Completer<Uint8List>();
    var sink = ByteConversionSink.withCallback(
      (bytes) => completer.complete(Uint8List.fromList(bytes)),
    );
    stream.listen(sink.add, onError: completer.completeError, onDone: sink.close, cancelOnError: true);
    return completer.future;
  }
}
