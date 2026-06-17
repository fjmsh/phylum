import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:phylum/libphylum/db/db.dart';

class NewUserDetails {
  final String email;
  final String name;

  NewUserDetails({required this.email, required this.name});
}

class NewUserDetailsDialog extends StatefulWidget {
  const NewUserDetailsDialog._();

  @override
  State<NewUserDetailsDialog> createState() => _NewUserDetailsDialogState();

  static Future<User?> show(BuildContext context) async {
    return showDialog<User>(
      context: context,
      barrierDismissible: true,
      builder: (context) => const NewUserDetailsDialog._(),
    );
  }
}

class _NewUserDetailsDialogState extends State<NewUserDetailsDialog> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Invite User'),
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
              textInputAction: TextInputAction.go,
              onSubmitted: (value) => done(),
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
              onPressed: EmailValidator.validate(email.text) ? done : null,
              child: const Text('Done'),
            );
          },
        ),
      ],
    );
  }

  void done() async {
    if (!EmailValidator.validate(_emailController.text)) return;
    Navigator.of(context).pop(
      NewUserDetails(email: _emailController.text, name: _nameController.text),
    );
  }
}
