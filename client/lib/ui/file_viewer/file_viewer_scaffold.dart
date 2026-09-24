import 'package:flutter/material.dart';
import 'package:phylum/ui/app/theme.dart';
import 'package:phylum/ui/explorer/properties/resource_properties_dialog.dart';

import 'versioned_resource.dart';
import 'package:phylum/integrations/download_manager.dart'
    if (dart.library.ffi) 'package:phylum/integrations/download_manager_vm.dart'
    if (dart.library.js_interop) 'package:phylum/integrations/download_manager_web.dart';

class FileViewerScaffold extends StatelessWidget {
  final VersionedResource? _resource;
  final Widget _body;
  final bool _transparent;

  const FileViewerScaffold({
    super.key,
    required this._resource,
    required this._body,
    this._transparent = true,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: PhylumTheme.dark,
      child: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Scaffold(
          backgroundColor: _transparent ? Colors.transparent : null,
          appBar: AppBar(
            // foregroundColor: colorScheme.onSurface,
            leading: const CloseButton(),
            actions: _resource == null
                ? null
                : [
                    IconButton(
                      icon: const Icon(Icons.info_outline),
                      onPressed: () =>
                          ResourcePropertiesDialog.show(context, _resource.r),
                    ),
                    IconButton(
                      onPressed: (_resource.r.dir)
                          ? null
                          : () => downloadResource(
                              context,
                              _resource.r,
                              version: _resource.v,
                            ),
                      icon: const Icon(Icons.download),
                    ),
                  ],
            title: Text(_resource?.name ?? 'Loading'),
            backgroundColor: Colors.transparent,
          ),
          body: Center(child: _body),
        ),
      ),
    );
  }
}
