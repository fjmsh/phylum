import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/actions/action_resource.dart';
import 'package:phylum/libphylum/actions/action_resource_publink_create.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/common/responsive_dialog.dart';
import 'package:phylum/ui/explorer/create_publink_view.dart';
import 'package:phylum/ui/explorer/explorer_controller.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';
import 'package:phylum/ui/explorer/resource_permissions_view.dart';
import 'package:phylum/ui/explorer/resource_sync_state.dart';
import 'package:phylum/util/file_size.dart';
import 'package:phylum/util/permissions.dart';
import 'package:phylum/util/time.dart';
import 'package:provider/provider.dart';
import 'package:state_notifier/state_notifier.dart';
import 'package:uri/uri.dart';

import 'resource_icon_extension.dart';

class ReactiveResourceInfoView extends StatelessWidget {
  const ReactiveResourceInfoView({super.key});

  @override
  Widget build(BuildContext context) {
    final resource = context.select<ExplorerState, Resource?>((state) {
      return state.focussedIfSelected ?? state.folder;
    });

    if (resource == null) {
      return const Center(child: Text(''));
    }
    return Column(
      children: [
        DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            border: Border(
              bottom: Divider.createBorderSide(context),
            ),
          ),
          child: ListTile(
            title: Text(resource.name, style: Theme.of(context).textTheme.bodyLarge),
          ),
        ),
        Expanded(child: SingleChildScrollView(child: ResourceInfoView(resource: resource))),
      ],
    );
  }
}

class ResourceInfoView extends StatelessWidget {
  final Resource resource;

  ResourceInfoView({required this.resource}) : super(key: ValueKey(resource.id));

  @override
  Widget build(BuildContext context) {
    final account = context.read<PhylumAccount>();
    final p = resource.permissions.parsePermissionMap();
    final myPermission = p.remove(account.userEmail) ?? 0;
    final repository = context.read<PhylumAccount>().userRepository;
    final entries = p.entries.toList(growable: false)..sort(((a, b) => a.key.compareTo(b.key)));
    final other = entries.map((e) => repository.getUserDisplayName(e.key)).join(', ');

    return ListTileTheme(
      data: ListTileThemeData(
        visualDensity: VisualDensity.adaptivePlatformDensity,
        titleTextStyle: Theme.of(context).textTheme.labelLarge,
        subtitleTextStyle: Theme.of(context).textTheme.bodyLarge,
      ),
      child: Column(
        children: [
          PendingActionsTile(resourceId: resource.id),
          ListTile(
            leading: resource.getIcon(),
            title: const Text('Type'),
            subtitle: Text(resource.dir ? 'Folder' : resource.contentType),
          ),
          ListTile(
            leading: const Icon(Icons.event),
            title: const Text('Created'),
            subtitle: Text(resource.created?.formatLong() ?? '--'),
          ),
          ListTile(
            leading: const Icon(Icons.edit_calendar),
            title: const Text('Modified'),
            subtitle: Text(resource.modified?.formatLong() ?? '--'),
          ),
          ListTile(
            leading: const Icon(Icons.account_circle),
            title: const Text('My Permissions'),
            subtitle: Text(myPermission.toStringFull()),
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Others with Access'),
            subtitle: other.isEmpty ? const Text('--') : Text(other),
            onTap: () => showReponsiveDialog(
                context, 'Permissions', (context) => ResourcePermissionsView(resourceId: resource.id)),
          ),
          StreamBuilder<List<String>>(
              stream: context.read<PhylumAccount>().db.selectPublinks(resource.id).map((l) => l.id).watch(),
              initialData: const [],
              builder: (context, snapshot) {
                final publinks = snapshot.data ?? const [];
                return ExpansionTile(
                  leading: const Icon(Icons.public),
                  title: const Text('Public Shares'),
                  subtitle: publinks.isEmpty ? const Text('--') : Text(publinks.length.toString()),
                  trailing: IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () async {
                      final account = context.read<PhylumAccount>();
                      final info = await CreatePublinkView.show(context, resource.id);
                      if (info == null) return;
                      account.addAction(ResourcePublinkCreateAction(
                        resourceId: resource.id,
                        publinkId: info.id,
                        password: info.password,
                        expires: info.expiration,
                        accessLimit: info.accessLimit,
                      ));
                    },
                  ),
                  initiallyExpanded: true,
                  children: publinks
                      .map((l) => ListTile(
                            dense: true,
                            title: Text(l),
                            trailing: IconButton(
                              icon: const Icon(Icons.copy),
                              onPressed: () {
                                final uri = kIsWeb
                                    ? UriBuilder.fromUri(Uri.base).path = 'publink/$l'
                                    : account.apiClient.createUri('publink/$l');
                                Clipboard.setData(ClipboardData(text: uri.toString()));
                              },
                            ),
                          ))
                      .toList(growable: false),
                );
              }),
          if (!resource.dir)
            ListTile(
              leading: const Icon(Icons.storage),
              title: const Text('Size'),
              subtitle: Text('${resource.contentLength.formatForDisplay()} (${resource.contentLength} B)'),
            ),
          if (!resource.dir)
            ListTile(
              leading: const Icon(Icons.shield),
              title: const Text('SHA-256'),
              onLongPress: () {
                Clipboard.setData(ClipboardData(text: resource.contentSha256));
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('SHA-256 checksum copied to clipboard'),
                  duration: const Duration(seconds: 2),
                ));
              },
              subtitle: Text(
                resource.contentSha256,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.fade,
              ),
            ),
        ],
      ),
    );
  }
}

class PendingActionsTile extends StatefulWidget {
  final String resourceId;

  const PendingActionsTile({super.key, required this.resourceId});

  @override
  State<PendingActionsTile> createState() => _PendingActionsTileState();
}

class _PendingActionsTileState extends State<PendingActionsTile> {
  RemoveListener? _removeListener;
  final Map<PhylumAction, RemoveListener> _listeners = {};
  final Map<PhylumAction, ActionStatus> _statusMap = {};

  @override
  void initState() {
    super.initState();
    _removeListener = context.read<PhylumActionQueue>().addListener((state) {
      final actions =
          state.actions.where((action) => action is ResourceAction && action.resourceId == widget.resourceId);
      for (final action in actions) {
        if (!_listeners.containsKey(action)) {
          _listeners[action] = action.statusNotifier.addListener((status) {
            if (_statusMap[action].runtimeType != status.runtimeType) {
              if (status is ActionStatusDone) {
                final l = _listeners.remove(action);
                _statusMap.remove(action);
                if (l != null) {
                  Future.microtask(() => l());
                }
              } else {
                _statusMap[action] = status;
              }
              if (mounted) {
                setState(() {});
              }
            }
          }, fireImmediately: true);
        }
      }
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _removeListener?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final e in _statusMap.entries)
          ListTile(
            visualDensity: VisualDensity.compact,
            dense: true,
            leading: Icon(ResourceSyncState.fromStatus(e.value).icon),
            title: Text(e.key.description, maxLines: 1),
          ),
      ],
    );
  }
}
