import 'package:flutter/material.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/requests/admin_user_password_update_request.dart';
import 'package:phylum/libphylum/responses/user_details.dart';
import 'package:phylum/libphylum/user_permission.dart';
import 'package:phylum/util/dialogs.dart';

class PasswordChangeDialog extends StatefulWidget {
  final PhylumAccount account;
  final UserDetails user;

  const PasswordChangeDialog({
    super.key,
    required this.account,
    required this.user,
  });

  @override
  State<PasswordChangeDialog> createState() => _PasswordChangeDialogState();

  static Future<List<UserPermission>?> show(
    BuildContext context,
    PhylumAccount account,
    UserDetails user,
  ) {
    return showDialog(
      context: context,
      builder: (context) => PasswordChangeDialog(account: account, user: user),
    );
  }
}

class _PasswordChangeDialogState extends State<PasswordChangeDialog> {
  final _controller = TextEditingController();
  bool requestInFlight = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: const Text('Set Password'),
      content: SizedBox(
        width: 360,
        child: TextField(
          controller: _controller,
          autofocus: true,
          autocorrect: false,
          obscureText: true,
          keyboardType: TextInputType.visiblePassword,
          onSubmitted: (value) => done(context),
        ),
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: () => Navigator.of(context).pop(null),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: requestInFlight ? null : () => done(context),
          child: requestInFlight ? const Text('Updating') : const Text('Done'),
        ),
      ],
    );
  }

  void done(BuildContext context) async {
    if (requestInFlight) return;

    setState(() => requestInFlight = true);
    final result = await widget.account.apiClient.sendRequest(
      AdminUserPasswordRequest(
        email: widget.user.email,
        password: _controller.text,
      ),
    );
    if (!context.mounted) return;
    setState(() => requestInFlight = false);
    if (result is ApiSuccessResponse) {
      Navigator.of(context).pop();
    } else {
      showAlertDialog(
        context,
        title: 'Error Updating Password',
        message: result.description,
      );
    }
  }
}
