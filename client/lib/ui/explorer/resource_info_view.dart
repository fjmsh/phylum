import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/actions/action_resource.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/explorer/explorer_controller.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';
import 'package:phylum/ui/explorer/resource_sync_state.dart';
import 'package:phylum/util/file_size.dart';
import 'package:phylum/util/permissions.dart';
import 'package:phylum/util/time.dart';
import 'package:provider/provider.dart';
import 'package:state_notifier/state_notifier.dart';

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
            leading: resource.getIcon(),
            title: Text(resource.name, style: TextStyle(fontSize: 20)),
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
    final publinks =
        resource.publinks == null ? const <String>[] : (jsonDecode(resource.publinks!) as List).cast<String>();

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
            title: const Text('Type'),
            subtitle: Text(resource.dir ? 'Folder' : resource.contentType),
          ),
          ListTile(
            title: const Text('Created'),
            subtitle: Text(resource.created?.formatForDisplay() ?? '--'),
          ),
          ListTile(
            title: const Text('Modified'),
            subtitle: Text(resource.modified?.formatForDisplay() ?? '--'),
          ),
          if (!resource.dir)
            ListTile(
              title: const Text('Size'),
              subtitle: Text(resource.contentLength.formatForDisplay()),
            ),
          if (!resource.dir)
            ListTile(
              title: const Text('SHA-256'),
              subtitle: Text(
                resource.contentSha256,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.fade,
              ),
            ),
          ListTile(
            title: const Text('My Permissions'),
            subtitle: Text(myPermission.toStringFull()),
          ),
          ListTile(
            title: const Text('Others with Access'),
            subtitle: other.isEmpty ? const Text('--') : Text(other),
          ),
          ListTile(
            title: const Text('Public Shares'),
            subtitle: publinks.isEmpty ? const Text('--') : Text(publinks.join(', ')),
            trailing: IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {},
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
