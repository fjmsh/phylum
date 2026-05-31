import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:phylum/ui/setup/setup_auth_fragment.dart';
import 'package:provider/provider.dart';
import 'package:state_notifier/state_notifier.dart';

class SetupUserFragment extends StatelessWidget {
  final formKey = GlobalKey<FormState>();
  final String instanceUrl;
  final void Function() onPrevPress;
  final void Function(BuildContext) onFinish;

  SetupUserFragment({
    super.key,
    required this.instanceUrl,
    required this.onPrevPress,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: SingleChildScrollView(child: buildContents(context))),
        TextButtonTheme(
          data: TextButtonThemeData(
            style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: onPrevPress,
                child: Text('PREV'),
              ),
              TextButton(
                onPressed: () => validateAndNext(context),
                child: Text('FINISH'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildContents(BuildContext context) {
    final config = context.watch<UserConfig>();
    final passwordRequired = context
        .select<AuthConfig, bool>((config) => config.passwordLoginEnabled);

    return Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 18.0,
        children: [
          Text('Admin User', style: Theme.of(context).textTheme.headlineSmall),
          SizedBox(height: 6),
          TextFormField(
            decoration: const InputDecoration(
              label: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: 'Email '),
                    TextSpan(text: '*', style: TextStyle(color: Colors.red))
                  ],
                ),
              ),
              prefixIcon: Icon(Icons.email),
              hint: Text('admin@example.com'),
            ),
            autofocus: true,
            autocorrect: false,
            keyboardType: TextInputType.url,
            initialValue: config.email,
            onChanged: (value) => context.read<UserController>().email = value,
            validator: (value) => value?.isEmpty ?? true
                ? 'Required'
                : EmailValidator.validate(value!)
                    ? null
                    : 'Invalid Email Address',
          ),
          TextFormField(
            decoration: const InputDecoration(
              label: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: 'Full Name '),
                    TextSpan(text: '*', style: TextStyle(color: Colors.red))
                  ],
                ),
              ),
              prefixIcon: Icon(Icons.person),
              hint: Text('Admin'),
            ),
            keyboardType: TextInputType.name,
            textCapitalization: TextCapitalization.words,
            initialValue: config.name,
            onChanged: (value) => context.read<UserController>().name = value,
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),
          if (passwordRequired)
            TextFormField(
              decoration: const InputDecoration(
                label: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: 'Password '),
                      TextSpan(text: '*', style: TextStyle(color: Colors.red))
                    ],
                  ),
                ),
                prefixIcon: Icon(Icons.password),
              ),
              autocorrect: false,
              obscureText: true,
              initialValue: config.password,
              onChanged: (value) =>
                  context.read<UserController>().password = value,
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
        ],
      ),
    );
  }

  Future<void> validateAndNext(BuildContext context) async {
    if (formKey.currentState?.validate() == false) return;
    onFinish(context);
  }
}

class UserController extends StateNotifier<UserConfig> {
  UserController() : super(UserConfig.defaults());

  set email(String value) {
    state = state.copyWith(email: value);
  }

  set name(String value) {
    state = state.copyWith(name: value);
  }

  set password(String value) {
    state = state.copyWith(password: value);
  }
}

class UserConfig {
  final String email;
  final String name;
  final String password;

  const UserConfig({
    required this.email,
    required this.name,
    required this.password,
  });

  const UserConfig.defaults()
      : this(
          email: '',
          name: '',
          password: '',
        );

  UserConfig copyWith({
    String? email,
    String? name,
    String? password,
  }) {
    return UserConfig(
      email: email ?? this.email,
      name: name ?? this.name,
      password: password ?? this.password,
    );
  }

  Map<String, dynamic> toMap() => {
        'email': email,
        'name': name,
        'password': password,
      };
}
