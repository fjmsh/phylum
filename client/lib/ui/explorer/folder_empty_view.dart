import 'package:flutter/material.dart';

enum FolderEmptyViewType { loading, noData, error }

class FolderEmptyView extends StatelessWidget {
  final FolderEmptyViewType type;
  final GlobalKey<RefreshIndicatorState> refreshKey;
  final Future<void> Function() onRefresh;

  const FolderEmptyView({
    super.key,
    required this.refreshKey,
    required this.type,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      child: LayoutBuilder(
        builder: (context, constraints) => RefreshIndicator(
          key: refreshKey,
          onRefresh: onRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: constraints.maxWidth,
                minHeight: constraints.maxHeight,
              ),
              child: DefaultTextStyle.merge(
                style: TextStyle(fontSize: 18),
                child: Center(child: _buildContents()),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContents() => switch (type) {
    FolderEmptyViewType.loading => const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.only(right: 16),
          child: CircularProgressIndicator(),
        ),
        Text('Loading'),
      ],
    ),
    FolderEmptyViewType.noData => const Text('No files here'),
    FolderEmptyViewType.error => const Text('Error Loading Data'),
  };
}
