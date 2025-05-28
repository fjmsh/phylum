import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';

class NewUserDetailsDialog extends StatefulWidget {
  const NewUserDetailsDialog._();

  @override
  State<NewUserDetailsDialog> createState() => _NewUserDetailsDialogState();

  static Future<(String, String)?> show(BuildContext context) async {
    return showDialog(context: context, barrierDismissible: true, builder: (context) => const NewUserDetailsDialog._());
  }
}

class _NewUserDetailsDialogState extends State<NewUserDetailsDialog> {
  String name = '';
  String email = '';
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
              autofocus: true,
              textCapitalization: TextCapitalization.none,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              onChanged: (value) {
                setState(() {
                  email = value;
                });
              },
            ),
            TextField(
              decoration: InputDecoration(
                labelText: 'Name (optional)',
                hintText: 'Din Djarin',
              ),
              textCapitalization: TextCapitalization.words,
              keyboardType: TextInputType.name,
              textInputAction: TextInputAction.go,
              onChanged: (value) {
                name = value;
              },
              onSubmitted: EmailValidator.validate(email) ? (value) => Navigator.of(context).pop((email, name)) : null,
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
            Navigator.of(context).pop(false);
          },
        ),
        ElevatedButton(
          onPressed: EmailValidator.validate(email) ? () => Navigator.of(context).pop((email, name)) : null,
          child: const Text('Invite'),
        )
      ],
    );
  }
}
