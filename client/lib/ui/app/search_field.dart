import 'package:flutter/material.dart';
import 'package:phylum/ui/app/router.dart';
import 'package:phylum/ui/explorer/explorer_controller.dart';
import 'package:phylum/ui/explorer/page.dart';
import 'package:provider/provider.dart';

class SearchField extends StatefulWidget {
  final FocusNode focusNode;

  const SearchField({super.key, required this.focusNode});

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<ExplorerController>().addListener((state) {
      final page = state.page;
      if (page is ExplorerPageSearch) {
        _controller.text = page.query;
      } else {
        _controller.text = '';
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Actions(
      actions: {
        DismissIntent: CallbackAction<DismissIntent>(onInvoke: (i) => widget.focusNode.nextFocus()),
      },
      child: TextField(
        decoration: InputDecoration.collapsed(
          hintText: 'Search Files...',
          hintStyle: TextStyle(fontSize: 18),
        ),
        focusNode: widget.focusNode,
        controller: _controller,
        style: TextStyle(fontSize: 18),
        onSubmitted: (text) {
          final query = text.trim();
          if (query.isNotEmpty) {
            context.read<PhylumRouterDelegate>().go(ExplorerPageSearch(query: query));
          }
        },
      ),
    );
  }
}
