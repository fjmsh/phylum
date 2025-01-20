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
import 'package:phylum/libphylum/db/resource_helpers.dart';
import 'package:phylum/libphylum/parsers/parsers.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/requests/resource_contents_request.dart';
import 'package:phylum/ui/common/responsive_dialog.dart';
import 'package:phylum/ui/explorer/resource_info_view.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

const maxPreviewSize = 1 * 1024 * 1024;

class ResourcePreview extends StatefulWidget {
  final List<Resource> resources;
  final int index;

  const ResourcePreview({super.key, required this.resources, required this.index});

  static Future<void> showPreview(BuildContext context, List<Resource> resources, int index) async {
    context.read<PhylumAccount>().db.markResourceAccess(resources[index].id);
    return showDialog(context: context, builder: (context) => ResourcePreview(resources: resources, index: index));
  }

  @override
  State<ResourcePreview> createState() => _ResourcePreviewState();
}

class _ResourcePreviewState extends State<ResourcePreview> {
  late int index;
  late Resource _resource;
  final _focusNode = FocusNode();
  String? _error;
  Widget Function(Uint8List)? _buildPreview;

  @override
  void initState() {
    super.initState();
    index = widget.index;
    _updateResource();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _updateResource() {
    _resource = widget.resources[index];
    if (_resource.dir) {
      _error = 'Cannot preview directory';
    } else if (_resource.contentLength > maxPreviewSize) {
      _error = 'Resource too large to preview';
    } else {
      if (_resource.contentType.startsWith('image/')) {
        _buildPreview = buildImagePreview;
      }
      if (_resource.contentType.startsWith('text/')) {
        _buildPreview = buildTextPreview;
      }
      if (_resource.contentType == 'application/pdf') {
        _buildPreview = buildPdfPreview;
      }
      if (_buildPreview == null) {
        _error = 'Unable to preview ${_resource.contentType}';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Actions(
      actions: {
        DismissIntent: CallbackAction<DismissIntent>(
          onInvoke: (i) => Navigator.of(context).pop(),
        ),
        FocusLeftIntent: CallbackAction<FocusLeftIntent>(onInvoke: (FocusLeftIntent i) {
          return setState(() {
            if (index <= 0) {
              index = widget.resources.length;
            }
            index--;
            _updateResource();
          });
        }),
        FocusRightIntent: CallbackAction<FocusRightIntent>(onInvoke: (FocusRightIntent i) {
          return setState(() {
            index++;
            if (index >= widget.resources.length) {
              index = 0;
            }
            _updateResource();
          });
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
                  icon: const Icon(Icons.info_outline),
                  onPressed: () => showReponsiveDialog(
                    context,
                    _resource.name,
                    (context) => ResourceInfoView(resource: _resource),
                  ),
                ),
                IconButton(
                  onPressed: (_resource.dir) ? null : () => downloadResource(),
                  icon: const Icon(Icons.download),
                )
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
        final error = parseErrorResponse(await response.bodyString()).message;
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
