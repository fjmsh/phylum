import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phylum/ui/settings/auth/form/openid_config_cubit.dart';

class OpenIDConfigDialog extends StatelessWidget {
  final OpenIDConfigFormCubit _bloc;

  const OpenIDConfigDialog._({required this._bloc});

  static Future<OpenIDConfig?> show(
    BuildContext context, {
    required OpenIDConfig config,
  }) async {
    final bloc = OpenIDConfigFormCubit(config: config);
    return showDialog<OpenIDConfig>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('OpenID Client Configuration'),
        content: OpenIDConfigDialog._(bloc: bloc),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final nav = Navigator.of(context);
              final result = bloc.validate();
              if (result == null) return;
              nav.pop(bloc.state);
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 12.0,
      children: [
        BlocBuilder<OpenIDConfigFormCubit, OpenIDConfig>(
          bloc: _bloc,
          builder: (context, state) {
            return TextFormField(
              decoration: InputDecoration(
                label: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: 'Name '),
                      TextSpan(
                        text: '*',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
                hint: Text('Authelia'),
                errorText: state.nameError,
              ),
              autofocus: true,
              autocorrect: false,
              enabled: !state.isNameFixed,
              textCapitalization: TextCapitalization.words,
              initialValue: state.name,
              onChanged: (value) => _bloc.name = value,
            );
          },
          buildWhen: (previous, current) =>
              previous.nameError != current.nameError,
        ),
        BlocBuilder<OpenIDConfigFormCubit, OpenIDConfig>(
          bloc: _bloc,
          builder: (context, state) {
            return TextFormField(
              decoration: InputDecoration(
                label: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: 'Issuer URL '),
                      TextSpan(
                        text: '*',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
                hint: Text('https://auth.example.com'),
                errorText: state.issuerUrlError,
              ),
              enabled: !state.isIssuerUrlFixed,
              keyboardType: TextInputType.url,
              initialValue: state.issuerUrl,
              onChanged: (value) => _bloc.issuerUrl = value,
            );
          },
          buildWhen: (previous, current) =>
              previous.issuerUrlError != current.issuerUrlError,
        ),
        BlocBuilder<OpenIDConfigFormCubit, OpenIDConfig>(
          bloc: _bloc,
          builder: (context, state) {
            return TextFormField(
              decoration: InputDecoration(
                label: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: 'Client ID '),
                      TextSpan(
                        text: '*',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
                hint: Text('phylum'),
                errorText: state.clientIdError,
              ),
              enabled: !state.isClientIdFixed,
              autocorrect: false,
              initialValue: state.clientId,
              onChanged: (value) => _bloc.clientId = value,
            );
          },
          buildWhen: (previous, current) =>
              previous.clientIdError != current.clientIdError,
        ),
        BlocBuilder<OpenIDConfigFormCubit, OpenIDConfig>(
          bloc: _bloc,
          builder: (context, state) {
            return TextFormField(
              decoration: InputDecoration(
                label: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: 'Client Secret '),
                      TextSpan(
                        text: '*',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
                errorText: state.clientSecretError,
              ),
              obscureText: true,
              enabled: !state.isClientSecretFixed,
              initialValue: state.clientSecret,
              onChanged: (value) => _bloc.clientSecret = value,
            );
          },
          buildWhen: (previous, current) =>
              previous.clientSecretError != current.clientSecretError,
        ),
        BlocBuilder<OpenIDConfigFormCubit, OpenIDConfig>(
          bloc: _bloc,
          builder: (context, state) {
            return SwitchListTile(
              value: state.allowUnverifiedEmails,
              title: Text('Allow Unverified Emails'),
              subtitle: Text('Use with caution'),
              visualDensity: VisualDensity.compact,
              onChanged: state.isAllowUnverifiedEmailsFixed
                  ? null
                  : (value) => _bloc.allowUnverifiedEmails = value,
            );
          },
          buildWhen: (previous, current) =>
              previous.allowUnverifiedEmails != current.allowUnverifiedEmails,
        ),
        BlocBuilder<OpenIDConfigFormCubit, OpenIDConfig>(
          bloc: _bloc,
          builder: (context, state) {
            return SwitchListTile(
              value: state.autoCreateUsers,
              title: Text('Auto-create Accounts'),
              subtitle: Text('Only use with trusted private providers'),
              visualDensity: VisualDensity.compact,
              onChanged: state.isAutoCreateUsersFixed
                  ? null
                  : (value) => _bloc.autoCreateUsers = value,
            );
          },
          buildWhen: (previous, current) =>
              previous.autoCreateUsers != current.autoCreateUsers,
        ),
      ],
    );
  }
}
