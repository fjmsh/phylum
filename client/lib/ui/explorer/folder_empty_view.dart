import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'explorer_view_controller.dart';

enum FolderEmptyViewType {
  loading,
  noData,
  error,
}

class FolderEmptyView extends StatelessWidget {
  final FolderEmptyViewType type;

  const FolderEmptyView({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      child: LayoutBuilder(
        builder: (context, constraints) => RefreshIndicator(
          onRefresh: context.read<ExplorerViewController>().refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: constraints.maxWidth,
                minHeight: constraints.maxHeight,
              ),
              child: Center(child: _buildContents()),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContents() => switch (type) {
        FolderEmptyViewType.loading => const CircularProgressIndicator(),
        FolderEmptyViewType.noData => const Text('Nothing Here...'),
        FolderEmptyViewType.error => const Text('Error Loading Data'),
      };
}
