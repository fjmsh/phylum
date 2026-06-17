import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/requests/admin_user_create_request.dart';
import 'package:phylum/libphylum/responses/user_details.dart';
import 'package:phylum/util/dialogs.dart';
import 'package:provider/provider.dart';

class CreateUserDialog extends StatefulWidget {
  final PhylumAccount account;

  const CreateUserDialog._({required this.account});

  @override
  State<CreateUserDialog> createState() => _CreateUserDialogState();

  static Future<UserDetails?> show(BuildContext context) async {
    final account = context.read<PhylumAccount>();
    return showDialog<UserDetails>(
      context: context,
      barrierDismissible: true,
      builder: (context) => CreateUserDialog._(account: account),
    );
  }
}

class _CreateUserDialogState extends State<CreateUserDialog> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool sendEmail = true;
  bool createHome = true;
  bool requestInFlight = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create User'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 12.0,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Email',
                hintText: 'djarin@example.com',
              ),
              controller: _emailController,
              autofocus: true,
              textCapitalization: TextCapitalization.none,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
            ),
            TextField(
              decoration: InputDecoration(
                labelText: 'Name (optional)',
                hintText: 'Din Djarin',
              ),
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              keyboardType: TextInputType.name,
              textInputAction: TextInputAction.next,
            ),
            TextField(
              decoration: InputDecoration(labelText: 'Password'),
              controller: _passwordController,
              obscureText: true,
              keyboardType: TextInputType.visiblePassword,
              textInputAction: TextInputAction.go,
              onSubmitted: (value) => done(context),
            ),
            SwitchListTile(
              title: Text('Send Welcome Email'),
              value: sendEmail,
              onChanged: (value) {
                setState(() {
                  sendEmail = value;
                });
              },
            ),
            SwitchListTile(
              title: Text('Create Home Directory'),
              value: createHome,
              onChanged: (value) {
                setState(() {
                  createHome = value;
                });
              },
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text(
            'Cancel',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          onPressed: () {
            Navigator.of(context).pop(null);
          },
        ),
        ValueListenableBuilder(
          valueListenable: _emailController,
          builder: (context, email, child) {
            return ElevatedButton(
              onPressed: !requestInFlight && EmailValidator.validate(email.text)
                  ? () => done(context)
                  : null,
              child: requestInFlight
                  ? const Text('Creating')
                  : const Text('Create'),
            );
          },
        ),
      ],
    );
  }

  void done(BuildContext context) async {
    if (requestInFlight) return;
    if (!EmailValidator.validate(_emailController.text)) return;

    setState(() => requestInFlight = true);
    final result = await widget.account.apiClient.sendRequest(
      AdminUserCreateRequest(
        email: _emailController.text,
        name: _nameController.text,
        password: _passwordController.text,
        noSendEmail: !sendEmail,
        noCreateHome: !createHome,
      ),
    );
    if (!context.mounted) return;
    setState(() => requestInFlight = false);
    if (result is UserDetails) {
      Navigator.of(context).pop(result);
    } else {
      showAlertDialog(
        context,
        title: 'Error Creating User',
        message: result.description,
      );
    }
  }
}
