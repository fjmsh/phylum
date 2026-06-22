part of 'destination_picker.dart';

class _ActionHandler extends StatelessWidget {
  final Widget child;
  final FocusNode focusNode;
  const _ActionHandler({required this.child, required this.focusNode});

  @override
  Widget build(BuildContext context) {
    return Actions(
      actions: {
        NavUpIntent: CallbackAction<NavUpIntent>(
          onInvoke: (i) async {
            final parentId = context.read<ExplorerState>().folder?.parent;
            if (parentId != null) {
              context.read<ExplorerHistoryController>().go(
                ExplorerLocationFolder(folderId: parentId),
              );
            }
            focusNode.requestFocus();
            return null;
          },
        ),
        FocusDownIntent: CallbackAction<FocusDownIntent>(
          onInvoke: (i) async {
            context.read<ExplorerController>().updateSelection(
              (i) => i + 1,
              SelectionMode.single,
              false,
            );
            focusNode.requestFocus();
            return null;
          },
        ),
        FocusUpIntent: CallbackAction<FocusUpIntent>(
          onInvoke: (i) async {
            context.read<ExplorerController>().updateSelection(
              (i) => i - 1,
              SelectionMode.single,
              false,
            );
            focusNode.requestFocus();
            return null;
          },
        ),
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (i) async {
            final selected = context.read<ExplorerState>().selectedSingle;
            if (selected != null && selected.dir) {
              context.read<ExplorerHistoryController>().go(
                ExplorerLocationFolder(folderId: selected.id),
              );
            }
            return null;
          },
        ),
        DismissIntent: CallbackAction<DismissIntent>(
          onInvoke: (i) => Navigator.of(context).pop(),
        ),
      },
      child: child,
    );
  }
}
