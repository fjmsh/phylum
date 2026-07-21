import 'package:flutter/material.dart';
import 'package:phylum/ui/settings/users/user_list_controller.dart';
import 'package:phylum/ui/settings/users/user_list_view.dart';
import 'package:provider/provider.dart';

class UsersPane extends StatefulWidget {
  const UsersPane({super.key});

  @override
  State<UsersPane> createState() => _UsersPaneState();
}

class _UsersPaneState extends State<UsersPane> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<UserListController>().maybeFetch(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (context.select<UserListState, bool>(
          (state) => (state.users?.length ?? 0) > 10,
        ))
          TextField(
            decoration: InputDecoration(
              suffixIcon: IconButton(
                onPressed: () {
                  context.read<UserListController>().filter = '';
                },
                padding: EdgeInsets.zero,
                icon: Icon(Icons.close),
                iconSize: 18,
              ),
              hintText: 'Start typing to filter...',
            ),
            autofocus: true,
            autocorrect: false,
            onChanged: (value) =>
                context.read<UserListController>().filter = value,
          ),
        Expanded(child: const UserListView()),
      ],
    );
  }
}
