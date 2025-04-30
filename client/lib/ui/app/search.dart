import 'package:flutter/material.dart';
import 'package:phylum/ui/app/router.dart';
import 'package:phylum/ui/explorer/page.dart';
import 'package:provider/provider.dart';

class PhylumSearchController with ChangeNotifier {
  late final PhylumRouterDelegate _routerDelegate;
  bool _active = false;
  bool get active => _active;
  set active(bool value) {
    _active = value;
    notifyListeners();
  }

  String _pageQuery = '';
  String get pageQuery => _pageQuery;

  PhylumSearchController(BuildContext context) {
    _routerDelegate = context.read<PhylumRouterDelegate>();
    _routerDelegate.addListener(_onUpdatePage);
  }

  void _onUpdatePage() {
    final page = _routerDelegate.currentConfiguration;
    if (page is ExplorerPageSearch) {
      _pageQuery = page.query;
    } else {
      _pageQuery = '';
    }
    active = false;
  }
}

class SearchField extends StatefulWidget {
  const SearchField({super.key});

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  final FocusNode _focusNode = FocusNode();
  final _controller = TextEditingController();
  late final PhylumRouterDelegate _routerDelegate;
  late final PhylumSearchController _searchNotifier;

  @override
  void initState() {
    super.initState();

    _routerDelegate = context.read();
    _routerDelegate.addListener(_onUpdatePage);
    _onUpdatePage();

    _searchNotifier = context.read();
    _searchNotifier.addListener(_onSearchUpdated);
    _onSearchUpdated();
  }

  void _onUpdatePage() {
    final page = _routerDelegate.currentConfiguration;
    if (page is ExplorerPageSearch) {
      _controller.text = page.query;
    } else {
      _controller.text = '';
    }
  }

  void _onSearchUpdated() {
    if (_searchNotifier.active) {
      if (!_focusNode.hasFocus) {
        _focusNode.requestFocus();
      }
    } else {
      if (_focusNode.hasFocus) {
        _focusNode.nextFocus();
      }
      _controller.text = _searchNotifier.pageQuery;
    }
  }

  @override
  void dispose() {
    _searchNotifier.removeListener(_onSearchUpdated);
    _routerDelegate.removeListener(_onUpdatePage);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Actions(
      actions: {
        DismissIntent:
            CallbackAction<DismissIntent>(onInvoke: (i) => context.read<PhylumSearchController>().active = false),
      },
      child: Focus(
        onFocusChange: (focus) => context.read<PhylumSearchController>().active = focus,
        child: TextField(
          decoration: InputDecoration.collapsed(
            hintText: 'Search Files...',
            hintStyle: TextStyle(fontSize: 18),
          ),
          focusNode: _focusNode,
          controller: _controller,
          style: TextStyle(fontSize: 18),
          onSubmitted: (text) {
            final query = text.trim();
            if (query.isNotEmpty) {
              context.read<PhylumRouterDelegate>().go(ExplorerPageSearch(query: query));
            }
          },
        ),
      ),
    );
  }
}
