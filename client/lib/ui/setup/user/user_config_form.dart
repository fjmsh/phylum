import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'user_config_form_cubit.dart';

class UserConfigForm extends StatelessWidget {
  final UserConfigFormCubit _bloc;

  final void Function(BuildContext) _onFormSubmitted;

  const UserConfigForm({
    super.key,
    required this._bloc,
    required this._onFormSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 18.0,
      children: [
        BlocBuilder<UserConfigFormCubit, UserConfigFormState>(
          bloc: _bloc,
          builder: (context, state) => TextFormField(
            decoration: InputDecoration(
              label: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: 'Email Address '),
                    TextSpan(
                      text: '*',
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
              hint: Text('you@example.com'),
              errorText: state.emailError,
              prefixIcon: Icon(Icons.email),
            ),
            autofocus: true,
            autocorrect: false,
            keyboardType: TextInputType.emailAddress,
            initialValue: state.email,
            onChanged: (value) => _bloc.email = value,
          ),
          buildWhen: (previous, current) =>
              previous.emailError != current.emailError,
        ),
        BlocBuilder<UserConfigFormCubit, UserConfigFormState>(
          bloc: _bloc,
          builder: (context, state) => TextFormField(
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
              errorText: state.name,
              prefixIcon: Icon(Icons.person),
            ),
            keyboardType: TextInputType.name,
            initialValue: state.name,
            onChanged: (value) => _bloc.name = value,
          ),
          buildWhen: (previous, current) =>
              previous.nameError != current.nameError,
        ),
        if (_bloc.state.passwordRequired)
          BlocBuilder<UserConfigFormCubit, UserConfigFormState>(
            bloc: _bloc,
            builder: (context, state) => TextFormField(
              decoration: InputDecoration(
                label: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: 'Password '),
                      TextSpan(
                        text: '*',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
                errorText: state.passwordError,
                prefixIcon: Icon(Icons.password),
              ),
              autocorrect: false,
              obscureText: true,
              initialValue: state.password,
              onChanged: (value) => _bloc.password = value,
              textInputAction: TextInputAction.go,
              onFieldSubmitted: (value) => _onFormSubmitted(context),
            ),
            buildWhen: (previous, current) =>
                previous.passwordError != current.passwordError,
          ),
      ],
    );
  }
}
