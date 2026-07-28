import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'db_config_form_cubit.dart';

class DbConfigForm extends StatelessWidget {
  final DbConfigFormCubit _bloc;
  final void Function(BuildContext) _onFormSubmitted;

  const DbConfigForm({
    super.key,
    required this._bloc,
    required this._onFormSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      child: Column(
        spacing: 18.0,
        children: [
          BlocBuilder<DbConfigFormCubit, DbConfigFormState>(
            bloc: _bloc,
            builder: (context, state) => TextFormField(
              decoration: InputDecoration(
                label: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: 'Host '),
                      if (!state.hasHostOverride())
                        TextSpan(
                          text: '*',
                          style: TextStyle(color: Colors.red),
                        ),
                    ],
                  ),
                ),
                hint: Text('localhost'),
                errorText: state.hostError,
                prefixIcon: Icon(Icons.lan),
              ),
              enabled: !state.hasHostOverride(),
              autofocus: true,
              autocorrect: false,
              keyboardType: TextInputType.url,
              initialValue: state.host,
              onChanged: (value) => _bloc.host = value,
            ),
            buildWhen: (previous, current) =>
                previous.hostError != current.hostError,
          ),
          BlocBuilder<DbConfigFormCubit, DbConfigFormState>(
            bloc: _bloc,
            builder: (context, state) => TextFormField(
              decoration: InputDecoration(
                label: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: 'Port '),
                      if (!state.hasPortOverride())
                        TextSpan(
                          text: '*',
                          style: TextStyle(color: Colors.red),
                        ),
                    ],
                  ),
                ),
                hint: Text('587'),
                errorText: state.portError,
                prefixIcon: Icon(Icons.cable),
              ),
              enabled: !state.hasPortOverride(),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              keyboardType: TextInputType.number,
              initialValue: state.port,
              onChanged: (value) => _bloc.port = value,
            ),
            buildWhen: (previous, current) =>
                previous.portError != current.portError,
          ),
          BlocBuilder<DbConfigFormCubit, DbConfigFormState>(
            bloc: _bloc,
            builder: (context, state) => TextFormField(
              decoration: InputDecoration(
                label: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: 'Database '),
                      if (!state.hasDbNameOverride())
                        TextSpan(
                          text: '*',
                          style: TextStyle(color: Colors.red),
                        ),
                    ],
                  ),
                ),
                hint: Text('phylum'),
                errorText: state.dbNameError,
                prefixIcon: Icon(Icons.contact_mail),
              ),
              enabled: !state.hasDbNameOverride(),
              autocorrect: false,
              initialValue: state.dbName,
              onChanged: (value) => _bloc.dbName = value,
            ),
            buildWhen: (previous, current) =>
                previous.dbNameError != current.dbNameError,
          ),
          BlocBuilder<DbConfigFormCubit, DbConfigFormState>(
            bloc: _bloc,
            builder: (context, state) => TextFormField(
              decoration: InputDecoration(
                label: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: 'User '),
                      if (!state.hasUserOverride())
                        TextSpan(
                          text: '*',
                          style: TextStyle(color: Colors.red),
                        ),
                    ],
                  ),
                ),
                hint: Text('phylum@example.com'),
                errorText: state.userError,
                prefixIcon: Icon(Icons.person),
              ),
              enabled: !state.hasUserOverride(),
              autocorrect: false,
              initialValue: state.user,
              onChanged: (value) => _bloc.user = value,
            ),
            buildWhen: (previous, current) =>
                previous.userError != current.userError,
          ),
          TextFormField(
            decoration: InputDecoration(
              label: Text('Password'),
              prefixIcon: Icon(Icons.password),
            ),
            enabled: !_bloc.state.hasPasswordOverride(),
            autocorrect: false,
            obscureText: true,
            initialValue: _bloc.state.password,
            onChanged: (value) => _bloc.password = value,
            textInputAction: TextInputAction.go,
            onFieldSubmitted: (value) => _onFormSubmitted(context),
          ),
        ],
      ),
    );
  }
}
