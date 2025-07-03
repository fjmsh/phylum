import 'package:flutter/material.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/responses/responses.dart';
import 'package:phylum/ui/app/dialog_scaffold.dart';
import 'package:phylum/ui/app/router.dart';
import 'package:phylum/ui/app/routes.dart';
import 'package:phylum/ui/preview/resource_preview.dart';
import 'package:provider/provider.dart';

class OpenResourcePage extends StatefulWidget {
  final PhylumAccount account;
  final String resourceId;

  const OpenResourcePage({super.key, required this.account, required this.resourceId});

  @override
  State<OpenResourcePage> createState() => _OpenResourcePageState();
}

class _OpenResourcePageState extends State<OpenResourcePage> {
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadResourceDetails());
  }

  void _loadResourceDetails() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final router = context.read<PhylumRouterDelegate>();
    final response = await widget.account.resourceRepository.requestResource(widget.resourceId);
    if (response is ResourceInfoResponse) {
      if (!mounted) return;
      final r = response.root.resource;
      if (r.dir) {
        router.go(ExplorerRouteFolder(folderId: r.id));
      } else {
        if (r.parent != null) {
          router.go(ExplorerRouteFolder(folderId: r.parent!));
        } else {
          router.go(const ExplorerRouteHome());
        }
        ResourcePreview.showResources(context, [r], 0);
      }
    } else if (response is ApiErrorResponse) {
      if (mounted) {
        setState(() {
          _error = response.description;
        });
      }
    }
    _loading = false;
  }

  @override
  Widget build(BuildContext context) {
    return PhylumDialogScaffold(child: _loading ? _buildLoading(context) : _buildError(context));
  }

  Widget _buildLoading(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 6.0,
      children: [
        CircularProgressIndicator(),
        Text('Loading Details'),
      ],
    );
  }

  Widget _buildError(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 6.0,
      children: [
        Text('Error Loading Details: $_error'),
        TextButton(
            onPressed: () {
              context.read<PhylumRouterDelegate>().go(const ExplorerRouteHome());
            },
            child: Text(
              'Go Home',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            )),
        ElevatedButton(onPressed: _loadResourceDetails, child: Text('Retry')),
      ],
    );
  }
}
