import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum FolderViewType {
  list(Icons.list, 'List View'),
  grid(Icons.grid_on, 'Grid View');

  final IconData icon;
  final String label;

  const FolderViewType(this.icon, this.label);
}

class FolderViewNotifier extends ChangeNotifier {
  FolderViewType _folderViewType = FolderViewType.list;

  FolderViewType get folderViewType => _folderViewType;
  set folderViewType(FolderViewType viewType) {
    _folderViewType = viewType;
    notifyListeners();
  }
}

class FolderViewToggleButton extends StatelessWidget {
  const FolderViewToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final selected = {context.watch<FolderViewNotifier>().folderViewType};

    return SegmentedButton(
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
