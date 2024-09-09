import 'package:flutter/material.dart';

enum FolderEmptyViewType {
  loading,
  noData,
  error,
}

class FolderEmptyView extends StatelessWidget {
  final FolderEmptyViewType type;
  final Future<void> Function() onRefresh;

  const FolderEmptyView({super.key, required this.type, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      child: LayoutBuilder(
        builder: (context, constraints) => RefreshIndicator(
          onRefresh: onRefresh,
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
