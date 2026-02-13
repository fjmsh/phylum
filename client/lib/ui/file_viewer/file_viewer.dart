import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/integrations/download_manager.dart';
import 'package:phylum/libphylum/db/imgres.dart';
import 'package:phylum/libphylum/db/resource_helpers.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/requests/resource_contents_request.dart';
import 'package:phylum/libphylum/requests/resource_img_request.dart';
import 'package:phylum/libphylum/responses/responses.dart';
import 'package:phylum/ui/common/responsive_dialog.dart';
import 'package:phylum/ui/explorer/resource_info_view.dart';
import 'package:phylum/ui/file_viewer/versioned_resource.dart';
import 'package:provider/provider.dart';

const maxPreviewSize = 1 * 1024 * 1024;

class FileViewer extends StatefulWidget {
  final bool transparent;
  final VersionedResource resource;
  const FileViewer({super.key, required this.transparent, required this.resource});

  @override
  State<FileViewer> createState() => _FileViewerState();
}

class _FileViewerState extends State<FileViewer> {
  late VersionedResource _resource;
  String? _error;
  Widget Function(Uint8List)? _buildViewer;
  bool _loadPreview = false;

  @override
  void initState() {
    super.initState();
    _updateResource(widget.resource);
  }

  @override
  void didUpdateWidget(covariant FileViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    setState(() {
      _updateResource(widget.resource);
    });
  }

  void _updateResource(VersionedResource resource) {
    _resource = resource;
    if (_resource.r.dir) {
      _buildViewer = null;
      _error = 'Cannot view directory';
    } else {
      _buildViewer = null;
      context.read<PhylumAccount>().db.markResourceAccess(_resource.r.id);
      if (_resource.v.mimeType.startsWith('text/')) {
        _buildViewer = buildTextPreview;
        _loadPreview = false;
      } else if ((_resource.v.imgres & imgResLarge) != 0) {
        _buildViewer = buildImagePreview;
        _loadPreview = true;
      } else if (_resource.v.mimeType.startsWith('image/')) {
        _buildViewer = buildImagePreview;
        _loadPreview = false;
      } else {
        _error = 'Preview not available';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: widget.transparent ? Colors.black45 : Colors.blueGrey[900],
      appBar: AppBar(
        foregroundColor: theme.colorScheme.onInverseSurface,
        leading: const CloseButton(),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => showReponsiveDialog(
              context,
              _resource.r.name,
              (context) => ResourceInfoView(resource: _resource.r),
            ),
          ),
          IconButton(
            onPressed: (_resource.r.dir) ? null : () => downloadResource(context, _resource.r, version: _resource.v),
            icon: const Icon(Icons.download),
          )
        ],
        title: Text(_resource.name),
        backgroundColor: Colors.transparent,
      ),
      body: Center(
          child: _buildViewer == null
              ? Card(
                  child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(_error ?? 'Unknown error', style: TextStyle(fontSize: 18)),
                ))
              : ResourceLoader(
                  resourceId: _resource.r.id,
                  versionId: _resource.v.id,
                  buildViewer: _buildViewer!,
                  loadPreview: _loadPreview,
                )),
    );
  }
}

class ResourceLoader extends StatefulWidget {
  final String resourceId;
  final String versionId;
  final Widget Function(Uint8List data) buildViewer;
  final bool loadPreview;

  ResourceLoader({
    required this.resourceId,
    required this.buildViewer,
    required this.versionId,
    required this.loadPreview,
  }) : super(key: ValueKey(versionId));

  @override
  State<ResourceLoader> createState() => _ResourceLoaderState();
}

class _ResourceLoaderState extends State<ResourceLoader> {
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
        child: widget.buildViewer(_data!),
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
      final request = widget.loadPreview
          ? ResourceImgRequest(widget.resourceId, versionId: widget.versionId, imgRes: imgResLarge)
          : ResourceContentsRequest(widget.resourceId, widget.versionId);
      final response = await account.apiClient.dispatchRequestRaw(request);
      if (response.statusCode < 200 || response.statusCode > 300) {
        final error = PhylumApiErrorResponse.fromResponseBody(await response.bodyString()).message;
        _error = error;
        _downloading = false;
        if (mounted) {
          setState(() {});
        }
        return;
      }

      final expected = response.contentLength?.toDouble();
      ByteStream stream = response.stream;
      if (expected != null) {
        int received = 0;
        _progress = 0;
        if (mounted) {
          setState(() {});
        }
        stream = _toByteStream(response.stream.map((s) {
          received += s.length;
          _progress = received / expected;
          if (mounted) {
            setState(() {});
          }
          return s;
        }));
      }
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
