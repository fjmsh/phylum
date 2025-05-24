import 'package:flutter/material.dart';
import 'package:phylum/ui/app/dialog_scaffold.dart';
import 'package:phylum/ui/app/routes.dart';
import 'package:phylum/ui/app/router.dart';
import 'package:provider/provider.dart';

class ResetPasswordPage extends StatefulWidget {
  final Uri instanceUri;
  final String email;
  final String token;

  const ResetPasswordPage({
    super.key,
    required this.instanceUri,
    required this.email,
    required this.token,
  });

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  bool passwordVisible = false;

  @override
  Widget build(BuildContext context) {
    return PhylumDialogScaffold(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 6.0,
        children: [
          const Text('Reset Password', style: TextStyle(fontSize: 18)),
          TextField(
            decoration: InputDecoration(
              label: Text('New Password'),
              suffixIcon: passwordVisible
                  ? IconButton(
                      icon: Icon(Icons.visibility_off_outlined),
                      onPressed: () => setState(() => passwordVisible = false),
                    )
                  : IconButton(
                      icon: Icon(Icons.visibility_outlined),
                      onPressed: () => setState(() => passwordVisible = true),
                    ),
            ),
            obscureText: !passwordVisible,
            enableSuggestions: false,
            autocorrect: false,
            autofocus: true,
            keyboardType: TextInputType.visiblePassword,
            onChanged: (value) {},
            onSubmitted: (value) {},
          ),
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                  onPressed: () => context.read<PhylumRouterDelegate>().go(ExplorerRouteHome()), child: Text('Cancel'))
            ],
          ),
        ],
      ),
    );
  }
}
