import 'package:flutter/material.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:provider/provider.dart';

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
    final resource = this.resource;
    return Theme(
      data: ThemeData.dark(),
      child: Scaffold(
        backgroundColor: Colors.black45,
        appBar: AppBar(
          leading: CloseButton(
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.download))],
          title: (resource != null) ? Text(resource.name) : null,
          backgroundColor: Colors.transparent,
        ),
        body: Center(
            child: loading
                ? const CircularProgressIndicator()
                : resource == null
                    ? const Text('Error loading details', style: TextStyle(fontSize: 18))
                    : buildPreview(resource)),
      ),
    );
  }

  Widget buildPreview(Resource r) {
    return const Text('Unable to display preview', style: TextStyle(fontSize: 18));
  }
}
