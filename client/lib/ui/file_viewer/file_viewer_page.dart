import 'package:flutter/material.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/db/resource_helpers.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/app/routing/router.dart';
import 'package:phylum/ui/file_viewer/file_viewer.dart';
import 'package:phylum/ui/file_viewer/file_viewer_scaffold.dart';
import 'package:phylum/ui/file_viewer/versioned_resource.dart';
import 'package:provider/provider.dart';

class FilePreviewPage extends StatefulWidget {
  final String resourceId;

  const FilePreviewPage._({required this.resourceId});

  static Widget create({
    required PhylumAccount account,
    required String resourceId,
  }) {
    return MultiProvider(
      providers: [
        Provider.value(value: account),
        Provider.value(value: account.actionQueue),
      ],
      child: FilePreviewPage._(resourceId: resourceId),
    );
  }

  @override
  State<FilePreviewPage> createState() => _ResourcePreviewDialogState();
}

class _ResourcePreviewDialogState extends State<FilePreviewPage> {
  String? error;
  Resource? resource;
  ResourceVersion? version;

  @override
  void initState() {
    super.initState();
    final account = context.read<PhylumAccount>();
    account.db
        .watchResource(widget.resourceId)
        .listen((r) => setState(() => resource = r));
    account.db
        .latestVersion(widget.resourceId)
        .watchSingleOrNull()
        .listen((v) => setState(() => version = v));
    _loadResourceDetails();
  }

  void _loadResourceDetails() async {
    final account = context.read<PhylumAccount>();
    final response = await account.resourceRepository.requestResource(
      widget.resourceId,
    );
    if (response is ApiErrorResponse) {
      if (mounted) {
        setState(() {
          error = response.description;
        });
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    VersionedResource? res;
    if (resource != null && version != null) {
      res = VersionedResource(r: resource!, v: version!, showTimestamp: false);
    }
    return Actions(
      actions: {
        DismissIntent: CallbackAction<DismissIntent>(
          onInvoke: (i) => Navigator.of(context).pop(),
        ),
      },
      child: FocusScope(
        autofocus: true,
        child: FileViewerScaffold(
          transparent: false,
          resource: res,
          body: res != null
              ? FileViewer(resource: res)
              : error == null
              ? _buildLoading(context)
              : _buildError(context),
        ),
      ),
    );
  }

  Widget _buildLoading(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 6.0,
      children: [CircularProgressIndicator(), Text('Loading Details')],
    );
  }

  Widget _buildError(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 6.0,
      children: [
        Text('Error Loading Details: $error'),
        TextButton(
          onPressed: () {
            context.read<PhylumRouterDelegate>().go(const HomeRoute());
          },
          child: Text(
            'Go Home',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
        ElevatedButton(onPressed: _loadResourceDetails, child: Text('Retry')),
      ],
    );
  }
}
