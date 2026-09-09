import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phylum/ui/config/mail/form/mail_config_form_cubit.dart';

class MailConfigForm extends StatefulWidget {
  final MailConfigCubit _bloc;
  final void Function(BuildContext) _onFormSubmitted;

  const MailConfigForm({
    super.key,
    required this._bloc,
    required this._onFormSubmitted,
  });

  @override
  State<MailConfigForm> createState() => _MailConfigFormState();
}

class _MailConfigFormState extends State<MailConfigForm> {
  final _fromEmailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fromEmailController.text = widget._bloc.state.fromEmail;
  }

  @override
  void dispose() {
    super.dispose();
    _fromEmailController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      child: Column(
        spacing: 18.0,
        children: [
          BlocBuilder<MailConfigCubit, MailConfigFormState>(
            bloc: widget._bloc,
            builder: (context, state) => SwitchListTile(
              title: Text('Enable'),
              value: state.enabled,
              onChanged: state.isEnabledFixed()
                  ? null
                  : (value) {
                      widget._bloc.enabled = value;
                    },
            ),
            buildWhen: (previous, current) =>
                previous.enabled != current.enabled,
          ),
          BlocBuilder<MailConfigCubit, MailConfigFormState>(
            bloc: widget._bloc,
            builder: (context, state) => TextFormField(
              decoration: InputDecoration(
                label: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: 'SMTP Host '),
                      if (!state.isSmtpHostFixed())
                        TextSpan(
                          text: '*',
                          style: TextStyle(color: Colors.red),
                        ),
                    ],
                  ),
                ),
                hint: Text('localhost'),
                errorText: state.smtpHostError,
                prefixIcon: Icon(Icons.lan),
              ),
              enabled: state.enabled && !state.isSmtpHostFixed(),
              autofocus: true,
              autocorrect: false,
              keyboardType: TextInputType.url,
              initialValue: state.smtpHost,
              onChanged: (value) => widget._bloc.smtpHost = value,
            ),
            buildWhen: (previous, current) =>
                previous.enabled != current.enabled ||
                previous.smtpHostError != current.smtpHostError,
          ),
          BlocBuilder<MailConfigCubit, MailConfigFormState>(
            bloc: widget._bloc,
            builder: (context, state) => TextFormField(
              decoration: InputDecoration(
                label: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: 'SMTP Port '),
                      if (!state.isSmtpPortFixed())
                        TextSpan(
                          text: '*',
                          style: TextStyle(color: Colors.red),
                        ),
                    ],
                  ),
                ),
                hint: Text('587'),
                errorText: state.smtpPortError,
                prefixIcon: Icon(Icons.cable),
              ),
              enabled: state.enabled && !state.isSmtpPortFixed(),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              keyboardType: TextInputType.number,
              initialValue: state.smtpPort,
              onChanged: (value) => widget._bloc.smtpPort = value,
            ),
            buildWhen: (previous, current) =>
                previous.enabled != current.enabled ||
                previous.smtpPortError != current.smtpPortError,
          ),
          BlocBuilder<MailConfigCubit, MailConfigFormState>(
            bloc: widget._bloc,
            builder: (context, state) => TextFormField(
              decoration: InputDecoration(
                label: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: 'SMTP Username '),
                      if (!state.isSmtpUsernameFixed())
                        TextSpan(
                          text: '*',
                          style: TextStyle(color: Colors.red),
                        ),
                    ],
                  ),
                ),
                hint: Text('phylum@example.com'),
                errorText: state.smtpUsernameError,
                prefixIcon: Icon(Icons.person),
              ),
              enabled: state.enabled && !state.isSmtpUsernameFixed(),
              autocorrect: false,
              initialValue: state.smtpUsername,
              onChanged: (value) => widget._bloc.smtpUsername = value,
            ),
            buildWhen: (previous, current) =>
                previous.enabled != current.enabled ||
                previous.smtpUsernameError != current.smtpUsernameError,
          ),
          BlocBuilder<MailConfigCubit, MailConfigFormState>(
            bloc: widget._bloc,
            builder: (context, state) => TextFormField(
              decoration: InputDecoration(
                label: Text('SMTP Password'),
                hintText: '<unchanged>',
                prefixIcon: Icon(Icons.password),
              ),
              enabled: state.enabled && !state.isSmtpPasswordFixed(),
              autocorrect: false,
              obscureText: true,
              initialValue: state.smtpPassword,
              onChanged: (value) => widget._bloc.smtpPassword = value,
            ),
            buildWhen: (previous, current) =>
                previous.enabled != current.enabled,
          ),
          BlocBuilder<MailConfigCubit, MailConfigFormState>(
            bloc: widget._bloc,
            builder: (context, state) => TextFormField(
              decoration: InputDecoration(
                label: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: 'Mail From Name '),
                      if (!state.isFromNameFixed())
                        TextSpan(
                          text: '*',
                          style: TextStyle(color: Colors.red),
                        ),
                    ],
                  ),
                ),
                hint: Text('Phylum Drive'),
                errorText: state.fromNameError,
                prefixIcon: Icon(Icons.contact_mail),
              ),
              enabled: state.enabled && !state.isFromNameFixed(),
              autocorrect: false,
              initialValue: state.fromName,
              onChanged: (value) => widget._bloc.fromName = value,
            ),
            buildWhen: (previous, current) =>
                previous.enabled != current.enabled ||
                previous.fromNameError != current.fromNameError,
          ),
          BlocListener<MailConfigCubit, MailConfigFormState>(
            bloc: widget._bloc,
            listener: (BuildContext context, MailConfigFormState state) {
              if (state.fromEmail != _fromEmailController.text) {
                _fromEmailController.text = state.fromEmail;
              }
            },
            child: BlocBuilder<MailConfigCubit, MailConfigFormState>(
              bloc: widget._bloc,
              builder: (context, state) => TextFormField(
                decoration: InputDecoration(
                  label: Text.rich(
                    TextSpan(children: [TextSpan(text: 'Mail From Email')]),
                  ),
                  hint: Text('phylum@example.com'),
                  errorText: state.fromEmailError,
                  prefixIcon: Icon(Icons.alternate_email),
                ),
                enabled: state.enabled && !state.isFromEmailFixed(),
                autocorrect: false,
                controller: _fromEmailController,
                onChanged: (value) => widget._bloc.fromEmail = value,
              ),
              buildWhen: (previous, current) =>
                  previous.enabled != current.enabled ||
                  previous.fromEmailError != current.fromEmailError,
            ),
          ),
          BlocBuilder<MailConfigCubit, MailConfigFormState>(
            bloc: widget._bloc,
            builder: (context, state) => TextFormField(
              decoration: InputDecoration(
                label: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: 'Instance URL '),
                      if (!state.isInstanceFixed())
                        TextSpan(
                          text: '*',
                          style: TextStyle(color: Colors.red),
                        ),
                    ],
                  ),
                ),
                hint: Text('https://phylum.example.com'),
                errorText: state.instanceUrlError,
                prefixIcon: Icon(Icons.link),
              ),
              enabled: state.enabled && !state.isInstanceFixed(),
              autocorrect: false,
              keyboardType: TextInputType.url,
              initialValue: state.instanceUrl,
              onChanged: (value) => widget._bloc.instanceUrl = value,
              onFieldSubmitted: (value) => widget._onFormSubmitted(context),
            ),
            buildWhen: (previous, current) =>
                previous.enabled != current.enabled ||
                previous.instanceUrlError != current.instanceUrlError,
          ),
        ],
      ),
    );
  }
}
