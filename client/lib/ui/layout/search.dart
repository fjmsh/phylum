import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/app/shortcuts.dart';
import 'package:phylum/ui/app/router.dart';
import 'package:phylum/ui/app/page.dart';
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
    final account = context.read<PhylumAccount>();
    return Actions(
      actions: {
        DismissIntent:
            CallbackAction<DismissIntent>(onInvoke: (i) => context.read<PhylumSearchController>().active = false),
      },
      child: Focus(
          onFocusChange: (focus) => context.read<PhylumSearchController>().active = focus,
          child: TypeAheadField<Resource>(
            controller: _controller,
            focusNode: _focusNode,
            suggestionsCallback: (query) {
              query = query.trim().split(RegExp(r'\s')).join('%');
              if (query.length < 2) {
                return const [];
              }
              final select = account.db.resources.select()..where((r) => r.name.like('%$query%'));
              return select.get();
            },
            builder: (context, controller, focusNode) {
              return TextField(
                controller: controller,
                focusNode: focusNode,
                autofocus: true,
                decoration: InputDecoration.collapsed(
                  hintText: 'Search Files...',
                  hintStyle: TextStyle(fontSize: 18),
                ),
                style: TextStyle(fontSize: 18),
                onSubmitted: (text) => _query(),
              );
            },
            emptyBuilder: (context) => Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                _controller.text.trim().length < 2
                    ? 'Type to filter'
                    : 'No items found locally. Press \'enter\' to search server',
                // textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            hideOnEmpty: true,
            itemBuilder: (context, resource) {
              return ListTile(
                title: Text(resource.name),
              );
            },
            onQueried: _query,
            onSelected: (resource) {
              Actions.maybeInvoke(context, OpenResourceIntent(resource));
            },
          )),
    );
  }

  void _query() {
    final query = _controller.text.trim();
    if (query.isNotEmpty) {
      context.read<PhylumRouterDelegate>().go(ExplorerPageSearch(query: query));
    }
  }
}
