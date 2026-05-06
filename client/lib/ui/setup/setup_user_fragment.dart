import 'package:flutter/material.dart';
import 'package:phylum/ui/setup/setup_auth_fragment.dart';
import 'package:provider/provider.dart';
import 'package:state_notifier/state_notifier.dart';

class SetupUserFragment extends StatelessWidget {
  final String instanceUrl;

  const SetupUserFragment({super.key, required this.instanceUrl});

  @override
  Widget build(BuildContext context) {
    final config = context.watch<UserConfig>();
    final passwordRequired = context.select<AuthConfig, bool>((config) => config.passwordConfig?.cryptConfig != null);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12.0,
        children: [
          Text(
            'Admin User',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          TextFormField(
            decoration: const InputDecoration(label: Text('Email'), hint: Text('admin@example.com')),
            autofocus: true,
            autocorrect: false,
            keyboardType: TextInputType.url,
            initialValue: config.email,
            onChanged: (value) => context.read<UserController>().email = value,
          ),
          if (passwordRequired)
            TextFormField(
              decoration: const InputDecoration(label: Text('Password')),
              autocorrect: false,
              obscureText: true,
              initialValue: config.password,
              onChanged: (value) => context.read<UserController>().password = value,
            ),
        ],
      ),
    );
  }
}

class UserController extends StateNotifier<UserConfig> {
  UserController() : super(UserConfig.defaults());

  set email(String value) {
    state = state.copyWith(email: value);
  }

  set password(String value) {
    state = state.copyWith(password: value);
  }
}

class UserConfig {
  final String email;
  final String password;

  const UserConfig({
    required this.email,
    required this.password,
  });

  const UserConfig.defaults()
      : this(
          email: '',
          password: '',
        );

  UserConfig copyWith({
    String? email,
    String? password,
  }) {
    return UserConfig(
      email: email ?? this.email,
      password: password ?? this.password,
    );
  }

  Map<String, dynamic> toMap() => {
        'email': email,
        'password': password,
      };
}
