import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phylum/ui/settings/users/user_list_controller.dart';
import 'package:phylum/ui/settings/users/user_list_view.dart';
import 'package:provider/provider.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  bool _filtering = false;

  @override
  Widget build(BuildContext context) {
    final showSearch = context.select<UserListState, bool>(
      (state) => (state.users?.length ?? 0) > 10,
    );
    return Scaffold(
      appBar: AppBar(
        title: _filtering ? buildFilterTextField(context) : Text('Users'),
        actions: [
          if (showSearch && !_filtering)
            IconButton(
              onPressed: () => setState(() => _filtering = true),
              icon: Icon(Icons.search),
            ),
        ],
      ),
      body: const UserListView(),
    );
  }

  Widget buildFilterTextField(BuildContext context) {
    return Focus(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          setState(() => _filtering = false);
          context.read<UserListController>().filter = '';
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: TextField(
        autocorrect: false,
        decoration: InputDecoration(
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          suffixIcon: IconButton(
            onPressed: () {
              setState(() => _filtering = false);
              context.read<UserListController>().filter = '';
            },
            padding: EdgeInsets.zero,
            icon: Icon(Icons.close),
            iconSize: 18,
          ),
          hintText: 'Start typing to filter...',
        ),
        autofocus: true,
        onChanged: (value) => context.read<UserListController>().filter = value,
      ),
    );
  }
}
