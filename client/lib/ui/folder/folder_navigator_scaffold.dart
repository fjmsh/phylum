import 'dart:async';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:path/path.dart' as p;
import 'package:phylum/libphylum/actions/action_resource_mkdir.dart';
import 'package:phylum/libphylum/actions/action_resource_upload.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/common/expandable_fab.dart';
import 'package:phylum/ui/folder/nav_list.dart';
import 'package:phylum/ui/folder/folder_contents_view.dart';
import 'package:phylum/util/dialogs.dart';
import 'package:phylum/util/file_size.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import 'folder_navigator_stack.dart';

const uuid = Uuid();

class FolderNavigatorView extends StatelessWidget {
  final String root;

  const FolderNavigatorView({super.key, required this.root});

  @override
  Widget build(BuildContext context) {
    return StateNotifierProvider<FolderNavigatorStack, FolderNavigatorState>(
      create: (context) => FolderNavigatorStack(root),
      builder: (context, child) => const FolderScaffoldResponsive(),
    );
  }
}

class FolderScaffoldResponsive extends StatelessWidget {
  const FolderScaffoldResponsive({super.key});

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<FolderNavigatorState>();
    final folderId = nav.folderId;
    return MediaQuery.of(context).size.width < 800 ? FolderScaffoldDrawer(folderId: folderId) : FolderScaffoldSidebar(folderId: folderId);
  }
}

class FolderScaffoldDrawer extends StatelessWidget {
  final String folderId;
  FolderScaffoldDrawer({required this.folderId}) : super(key: ValueKey(folderId));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Phylum')),
      drawer: const Drawer(child: NavList(showFab: false)),
      floatingActionButton: ExpandableFab(
        distance: 112,
        children: [
          ActionButton(
            icon: const Icon(Icons.create_new_folder),
            onPressed: () async {
              final account = context.read<PhylumAccount>();
              final dirName = await showInputDialog(context, title: 'Create New Folder', labelText: 'Folder Name');
              if (dirName == null || dirName == "") return;
              account.addAction(ResourceMkdirAction(id: uuid.v4(), parent: folderId, resourceName: dirName));
            },
          ),
          ActionButton(
            icon: const Icon(Icons.upload_file),
            onPressed: () async {
              final account = context.read<PhylumAccount>();
              final files = await openFiles();
              for (final file in files) {
                final action = await ResourceUploadAction.fromPath(parent: folderId, resourceName: file.name, path: file.path);
                await account.addAction(action);
              }
            },
          ),
          ActionButton(
            icon: const Icon(Icons.drive_folder_upload_outlined),
            onPressed: () async {
              final account = context.read<PhylumAccount>();
              final path = await getDirectoryPath();
              if (path == null) return;
              if (!context.mounted) return;
              showProgressDialog(context, message: 'Counting Files');
              final tree = await DirTree.stat(path);

              if (!context.mounted) return;
              Navigator.of(context).pop();
              final confirm = await showAlertDialog(
                    context,
                    title: 'Upload Folder?',
                    message:
                        'Found ${tree.files.length} files and ${tree.dirs.length} directories.\n\nTotal Upload Size: ${tree.totalSize.getHumanString()}',
                    positiveText: 'YES',
                    negativeText: 'NO',
                  ) ??
                  false;
              if (!confirm || !context.mounted) return;
              final dirIds = <String, String>{};
              dirIds[path] = uuid.v4();
              account.addAction(ResourceMkdirAction(id: dirIds[path]!, parent: folderId, resourceName: p.basename(path)));
              for (final dir in tree.dirs) {
                dirIds[dir] = uuid.v4();
                final parent = p.dirname(dir);
                account.addAction(ResourceMkdirAction(id: dirIds[dir]!, parent: dirIds[parent]!, resourceName: p.basename(dir)));
              }
              for (final file in tree.files) {
                final parent = p.dirname(file);
                final action = await ResourceUploadAction.fromPath(parent: dirIds[parent]!, resourceName: p.basename(file), path: file);
                await account.addAction(action);
              }
            },
          ),
        ],
      ),
      body: FolderContentsView(id: folderId),
    );
  }
}

class DirTree {
  final int numFiles;
  final int numDirs;
  final int totalSize;
  final List<String> files;
  final List<String> dirs;

  DirTree({
    required this.numFiles,
    required this.numDirs,
    required this.totalSize,
    required this.files,
    required this.dirs,
  });

  static Future<DirTree> stat(String path) {
    final dir = Directory(path);
    final completer = Completer<DirTree>();
    final files = <String>[];
    final dirs = <String>[];
    int numFiles = 0;
    int numDirs = 0;
    int totalSize = 0;

    dir.list(recursive: true).listen(
      (file) {
        if (file is File) {
          numFiles++;
          totalSize += file.lengthSync();
          files.add(file.path);
        }
        if (file is Directory) {
          numDirs++;
          dirs.add(file.path);
        }
      },
      onDone: () => completer.complete(DirTree(
        numFiles: numFiles,
        numDirs: numDirs,
        totalSize: totalSize,
        files: files,
        dirs: dirs,
      )),
    );
    return completer.future;
  }
}

class FolderScaffoldSidebar extends StatelessWidget {
  final String folderId;
  FolderScaffoldSidebar({required this.folderId}) : super(key: ValueKey(folderId));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const NavList(showFab: false),
      body: Row(
        children: [
          SizedBox.fromSize(
            size: const Size.fromWidth(240),
            child: const NavList(showFab: true),
          ),
          Expanded(child: FolderContentsView(id: folderId)),
        ],
      ),
    );
  }
}
