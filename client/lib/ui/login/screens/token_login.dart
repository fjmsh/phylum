import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:phylum/ui/login/instance_url_field.dart';
import 'package:phylum/ui/login/util/login.dart';
import 'package:provider/provider.dart';
import 'package:uri/uri.dart';

import '../login_controller.dart';

class TokenLoginScreen extends StatefulWidget {
  final String? token;
  final String? error;

  const TokenLoginScreen({super.key, required this.token, required this.error});

  @override
  State<TokenLoginScreen> createState() => _TokenLoginScreenState();
}

class _TokenLoginScreenState extends State<TokenLoginScreen> {
  late final tokenController = TextEditingController(text: widget.token);
  bool _requestInFlight = false;

  @override
  void initState() {
    super.initState();
    if (widget.token?.isNotEmpty == true) {
      WidgetsBinding.instance.addPostFrameCallback((d) {
        _performLogin(context);
      });
    }
    if (widget.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.error!),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 18,
      children: [
        const InstanceUrlField(),
        TextField(
          decoration: InputDecoration(
            label: Text('Login Token'),
            hintText: 'AG...',
            suffixIcon: widget.token != null
                ? null
                : IconButton(
                    icon: Icon(Icons.paste),
                    onPressed: () async {
                      if (await Clipboard.hasStrings()) {
                        final data = await Clipboard.getData(
                          Clipboard.kTextPlain,
                        );
                        final text = data?.text;
                        if (text != null) {
                          tokenController.text = text;
                        }
                      }
                    },
                  ),
          ),
          controller: tokenController,
          readOnly: widget.token != null,
          keyboardType: TextInputType.text,
          autocorrect: false,
          autofocus: true,
          textInputAction: TextInputAction.go,
          onSubmitted: _requestInFlight
              ? null
              : (value) => _performLogin(context),
        ),
        ValueListenableBuilder(
          valueListenable: tokenController,
          builder: (_, token, __) => ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            label: Text(_requestInFlight ? 'Logging In' : 'Log In'),
            icon: _requestInFlight
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : Icon(Icons.login),
            onPressed: _requestInFlight || token.text.isEmpty
                ? null
                : () => _performLogin(context),
          ),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          label: Text('Back'),
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            context.read<LoginController>().selectedMethod = null;
          },
        ),
      ],
    );
  }

  Future<void> _performLogin(BuildContext context) async {
    if (_requestInFlight || tokenController.text.isEmpty) return;
    final instanceUrl = context.read<LoginState>().instanceUrl!;
    final builder = UriBuilder.fromUri(instanceUrl);
    builder.path = '${builder.path}/api/v1/auth/token/login';
    final request = MultipartRequest('post', builder.build());
    request.fields['token'] = tokenController.text;

    setState(() => _requestInFlight = true);
    await login(context, request);
    setState(() => _requestInFlight = false);
  }
}
