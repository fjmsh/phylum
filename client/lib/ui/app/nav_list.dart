import 'dart:async';

import 'package:flutter/material.dart';
import 'package:phylum/app_shortcuts.dart';
import 'package:phylum/integrations/download_manager.dart';
import 'package:phylum/ui/app/sync_button.dart';
import 'package:provider/provider.dart';

class NavList extends StatelessWidget {
  final bool showFab;
  const NavList({super.key, required this.showFab});

  @override
  Widget build(BuildContext context) {
    return ExcludeFocusTraversal(
      child: ListView(
        children: [
          if (showFab)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('New'),
                onPressed: () {
                  showMenu(
                    context: context,
                    position: const RelativeRect.fromLTRB(0, 0, 0, 0),
                    items: [
                      PopupMenuItem(child: const Text('Create Folder'), onTap: () => Actions.maybeInvoke(context, const NewFolderIntent())),
                      const PopupMenuItem(enabled: false, height: 16, child: Divider()),
                      PopupMenuItem(child: const Text('Upload File(s)'), onTap: () => Actions.maybeInvoke(context, const UploadFilesIntent())),
                      PopupMenuItem(child: const Text('Upload Folder'), onTap: () => Actions.maybeInvoke(context, const UploadFolderIntent())),
                    ],
                  );
                },
              ),
            ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () => Actions.maybeInvoke(context, const NavHomeIntent()),
          ),
          const Divider(),
          const DownloadButton(),
          const SyncButton(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class DownloadButton extends StatefulWidget {
  const DownloadButton({super.key});

  @override
  State<DownloadButton> createState() => _DownloadButtonState();
}

class _DownloadButtonState extends State<DownloadButton> {
  final listeners = <DownloadTask, void Function()>{};
  final lastStatus = <DownloadTask, DownloadStatus>{};
  late final StreamSubscription _subscription;
  int ongoing = 0;
  int received = 0;
  int total = 0;

  @override
  void initState() {
    super.initState();
    _subscription = context.read<DownloadManager>().stream.listen((state) {
      for (final task in state.running) {
        if (!listeners.containsKey(task)) {
          l() {
            final last = (lastStatus[task] as DownloadStatusRunning);
            final status = task.status.value;
            if (status is DownloadStatusRunning) {
              lastStatus[task] = status;
              setState(() {
                received += status.received - last.received;
                total += status.total - last.total;
              });
            } else {
              setState(() {
                ongoing--;
                received -= last.received;
                total -= last.total;
              });
              listeners.remove(task);
              lastStatus.remove(task);
              task.status.removeListener(l);
            }
          }

          final status = task.status.value;
          if (status is DownloadStatusRunning) {
            task.status.addListener(l);
            listeners[task] = l;
            lastStatus[task] = status;
            setState(() {
              ongoing++;
              received += status.received;
              total += status.total;
            });
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: ongoing == 0 ? const Icon(Icons.download) : const Icon(Icons.downloading),
      title: ongoing == 0 ? const Text('Downloads') : Text('Downloading $ongoing files'),
      subtitle: ongoing == 0
          ? null
          : LinearProgressIndicator(
              value: (received * 1.0 / total),
            ),
    );
  }
}
