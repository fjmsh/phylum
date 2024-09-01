import 'package:flutter/material.dart';
import 'package:phylum/ui/folder/folder_navigator_stack.dart';
import 'package:provider/provider.dart';

class FolderHeriarchyView extends StatelessWidget {
  const FolderHeriarchyView({super.key});

  @override
  Widget build(BuildContext context) {
    final navState = context.watch<FolderNavigatorState>();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: TextButtonTheme(
        data: TextButtonThemeData(
          style: ButtonStyle(
            textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 20)),
            padding: WidgetStateProperty.all(const EdgeInsets.all(16.0)),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              TextButton(
                onPressed: navState.isRoot ? null : () => context.read<FolderNavigatorStack>().popTo(0),
                child: Text(navState.name),
              ),
              for (final e in navState.stack.indexed)
                TextButton(
                  onPressed: (e.$1 == navState.stack.length - 1) ? null : () => context.read<FolderNavigatorStack>().popTo(e.$1 + 1),
                  child: Text(e.$2.$2),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
