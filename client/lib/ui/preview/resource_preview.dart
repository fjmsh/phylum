import 'package:flutter/material.dart';
import 'package:phylum/integrations/download_manager.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:provider/provider.dart';

const maxPreviewSize = 5 * 1024 * 1024;

class ResourcePreview extends StatefulWidget {
  final String resourceId;

  ResourcePreview({required this.resourceId}) : super(key: ValueKey(resourceId));

  static Future<void> showPreview(BuildContext context, String resourceId) async {
    return showDialog(context: context, builder: (context) => ResourcePreview(resourceId: resourceId));
  }

  @override
  State<ResourcePreview> createState() => _ResourcePreviewState();
}

class _ResourcePreviewState extends State<ResourcePreview> {
  bool loading = true;
  Resource? resource;

  @override
  void initState() {
    super.initState();
    context.read<PhylumAccount>().resourceRepository.getResource(widget.resourceId).then((r) => setState(() {
          loading = false;
          resource = r;
        }));
  }

  @override
  Widget build(BuildContext context) {
    final r = resource;
    return Theme(
      data: ThemeData.dark(),
      child: Scaffold(
        backgroundColor: Colors.black45,
        appBar: AppBar(
          leading: CloseButton(
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [IconButton(onPressed: (r == null || r.dir) ? null : () => downloadResource(r), icon: const Icon(Icons.download))],
          title: (r != null) ? Text(r.name) : null,
          backgroundColor: Colors.transparent,
        ),
        body: Center(
            child: loading
                ? const CircularProgressIndicator()
                : r == null
                    ? const Text('Error loading details', style: TextStyle(fontSize: 18))
                    : buildPreview(r)),
      ),
    );
  }

  Widget buildPreview(Resource r) {
    if (r.dir) {
      return const Text(
        'Cannot preview directory',
        style: TextStyle(fontSize: 18),
      );
    }
    if (r.size > maxPreviewSize) {
      return const Text(
        'File too large to preview',
        style: TextStyle(fontSize: 18),
      );
    }
    return switch (r.contentType) {
      'image/jpeg' || 'image/webp' || 'image/png' || 'image/gif' => buildImagePreview(r),
      _ => const Text('Unable to display preview', style: TextStyle(fontSize: 18)),
    };
  }

  Widget buildImagePreview(Resource r) {
    final api = context.read<PhylumAccount>().apiClient;
    return SizedBox(
      width: 800,
      child: Image.network(
        context.read<PhylumAccount>().apiClient.createUri('/api/v1/resources/contents/${r.id}').toString(),
        headers: api.requestHeaders,
      ),
    );
  }

  void downloadResource(Resource r) async {
    context.read<DownloadManager>().downloadResource(r);
  }
}
