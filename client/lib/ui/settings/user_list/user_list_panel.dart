import 'package:flutter/material.dart';
import 'package:phylum/ui/settings/user_list/user_list_controller.dart';
import 'package:phylum/ui/settings/user_list/user_list_view.dart';
import 'package:provider/provider.dart';

class UserListPanel extends StatefulWidget {
  const UserListPanel({super.key});

  @override
  State<UserListPanel> createState() => _UserListPanelState();
}

class _UserListPanelState extends State<UserListPanel> {
  @override
  void initState() {
    super.initState();
    context.read<UserListController>().maybeFetch();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (context.select<UserListState, bool>((state) => state.users != null))
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
