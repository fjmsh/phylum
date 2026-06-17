import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:provider/provider.dart';

const _persistKeyFolderViewType = 'folderViewType';

enum FolderViewType {
  list('list', Icons.list, 'List'),
  gridSmall('icons', Icons.grid_on, 'Icons (Small)'),
  gridLarge('icons-large', Icons.grid_view, 'Icons (Large)');

  final String name;
  final IconData icon;
  final String label;

  const FolderViewType(this.name, this.icon, this.label);

  static FolderViewType fromName(String? name) {
    return FolderViewType.values.firstWhereOrNull((v) => v.name == name) ??
        list;
  }
}

class FolderViewNotifier extends ChangeNotifier {
  late FolderViewType _folderViewType;

  FolderViewType get folderViewType => _folderViewType;

  final PhylumAccount _account;

  FolderViewNotifier(BuildContext context) : _account = context.read() {
    _folderViewType = FolderViewType.fromName(
      _account.getPersisted(_persistKeyFolderViewType) ?? 'list',
    );
  }

  set folderViewType(FolderViewType viewType) {
    _folderViewType = viewType;
    _account.persist(_persistKeyFolderViewType, _folderViewType.name);
    notifyListeners();
  }
}

class FolderViewToggleButton extends StatelessWidget {
  const FolderViewToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final selected = {context.watch<FolderViewNotifier>().folderViewType};

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: SegmentedButton(
        segments: [
          for (final viewType in FolderViewType.values)
            ButtonSegment(
              value: viewType,
              icon: Icon(viewType.icon),
              tooltip: viewType.label,
            ),
        ],
        onSelectionChanged: (selected) {
          context.read<FolderViewNotifier>().folderViewType = selected.first;
        },
        selected: selected,
      ),
    );
  }
}

class FolderViewIconButton extends StatelessWidget {
  const FolderViewIconButton({super.key});

  @override
  Widget build(BuildContext context) {
    final selected = context.watch<FolderViewNotifier>().folderViewType;
    final values = FolderViewType.values;
    final next = values[(values.indexOf(selected) + 1) % values.length];

    return IconButton(
      icon: Icon(next.icon),
      tooltip: next.label,
      onPressed: () {
        context.read<FolderViewNotifier>().folderViewType = next;
      },
    );
  }
}
