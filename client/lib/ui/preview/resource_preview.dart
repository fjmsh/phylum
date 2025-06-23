import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/integrations/download_manager.dart';
import 'package:phylum/ui/app/shortcuts.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/db/resource_helpers.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/requests/resource_contents_request.dart';
import 'package:phylum/libphylum/responses/responses.dart';
import 'package:phylum/ui/common/responsive_dialog.dart';
import 'package:phylum/ui/explorer/resource_info_view.dart';
import 'package:phylum/util/time.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

const maxPreviewSize = 1 * 1024 * 1024;

class VersionedResource {
  final Resource r;
  final ResourceVersion v;
  final bool latest;

  VersionedResource({required this.r, required this.v, required this.latest});

  String get name => latest ? r.name : '${r.name} - ${v.created.formatNumericDateTime()}';
}

class ResourcePreview extends StatefulWidget {
  final List<VersionedResource> resources;
  final int index;

  const ResourcePreview({super.key, required this.resources, required this.index});

  static Future<void> showResources(BuildContext context, List<Resource> resources, int index) async {
    final account = context.read<PhylumAccount>();
    final r = await Future.wait(resources
        .map((r) async => VersionedResource(r: r, v: await account.db.latestVersion(r.id).getSingle(), latest: true)));
    if (!context.mounted) return;
    show(context, r, index);
  }

  static Future<void> showVersions(
      BuildContext context, Resource resource, Iterable<ResourceVersion> versions, int index) async {
    final r = versions.map((v) => VersionedResource(r: resource, v: v, latest: false)).toList(growable: false);
    show(context, r, index);
  }

  static Future<void> show(BuildContext context, List<VersionedResource> resources, int index) async {
    final account = context.read<PhylumAccount>();
    account.db.markResourceAccess(resources[index].r.id);
    return showDialog(
        context: context,
        builder: (context) => MultiProvider(
                providers: [
                  Provider.value(value: account),
                  Provider.value(value: account.actionQueue),
                ],
                builder: (context, child) {
                  return ResourcePreview(resources: resources, index: index);
                }));
  }

  @override
  State<ResourcePreview> createState() => _ResourcePreviewState();
}

class _ResourcePreviewState extends State<ResourcePreview> {
  late int index;
  final _focusNode = FocusNode();
  String? _error;
  Widget Function(Uint8List)? _buildPreview;
  late VersionedResource _resource;

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
    if (_resource.r.dir) {
      _buildPreview = null;
      _error = 'Cannot preview directory';
    } else {
      setState(() {
        _buildPreview = null;
        if (_resource.v.mimeType.startsWith('image/')) {
          _buildPreview = buildImagePreview;
        }
        if (_resource.v.mimeType.startsWith('text/')) {
          _buildPreview = buildTextPreview;
        }
        if (_resource.v.mimeType == 'application/pdf') {
          _buildPreview = buildPdfPreview;
        }
        if (_buildPreview == null) {
          _error = 'Cannot generate preview';
        } else if (_resource.v.size > maxPreviewSize) {
          _buildPreview = null;
          _error = 'File too large to preview';
        }
      });
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
                    _resource.r.name,
                    (context) => ResourceInfoView(resource: _resource.r),
                  ),
                ),
                IconButton(
                  onPressed:
                      (_resource.r.dir) ? null : () => downloadResource(context, _resource.r, version: _resource.v),
                  icon: const Icon(Icons.download),
                )
              ],
              title: Text(_resource.name),
              backgroundColor: Colors.transparent,
            ),
            body: Center(
                child: _buildPreview == null
                    ? Card(
                        child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(_error ?? 'Unknown error', style: TextStyle(fontSize: 18)),
                      ))
                    : ResourcePreviewDownloader(
                        resourceId: _resource.r.id,
                        versionId: _resource.v.id,
                        buildPreview: _buildPreview!,
                      )),
          ),
        ),
      ),
    );
  }
}

class ResourcePreviewDownloader extends StatefulWidget {
  final String resourceId;
  final String versionId;
  final Widget Function(Uint8List data) buildPreview;

  ResourcePreviewDownloader({required this.resourceId, required this.buildPreview, required this.versionId})
      : super(key: ValueKey(versionId));

  @override
  State<ResourcePreviewDownloader> createState() => _ResourcePreviewDownloaderState();
}

class _ResourcePreviewDownloaderState extends State<ResourcePreviewDownloader> {
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
      final response = await account.apiClient.dispatchRequestRaw(ResourceContentsRequest(
        widget.resourceId,
        versionId: widget.versionId,
      ));
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

Widget buildPdfPreview(Uint8List data) => PdfPreview(
      build: (_) => data,
      previewPageMargin: EdgeInsets.zero,
    );
