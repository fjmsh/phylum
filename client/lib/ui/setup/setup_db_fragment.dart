import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phylum/ui/setup/db/db_config.dart';
import 'package:phylum/ui/setup/db/db_config_form.dart';
import 'package:phylum/ui/setup/db/db_config_form_cubit.dart';
import 'package:phylum/util/dialogs.dart';
import 'package:provider/provider.dart';
import 'package:state_notifier/state_notifier.dart';

class SetupDbFragment extends StatelessWidget {
  final DbConfigFormCubit _bloc;
  final void Function() onNextPress;

  const SetupDbFragment({
    super.key,
    required this._bloc,
    required this.onNextPress,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: DbConfigForm(bloc: _bloc, onFormSubmitted: validateAndNext),
          ),
        ),
        TextButtonTheme(
          data: TextButtonThemeData(
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(onPressed: null, child: Text('PREV')),
              TextButton(
                onPressed: () => validateAndNext(context),
                child: Text('NEXT'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildContents(BuildContext context) {
    final config = context.watch<DbConfig>();

    return Form(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 18.0,
        children: [
          Text('Database', style: Theme.of(context).textTheme.headlineSmall),
          SizedBox(height: 6),
          TextFormField(
            decoration: const InputDecoration(
              label: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: 'Host '),
                    TextSpan(
                      text: '*',
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
              hint: Text('localhost'),
              prefixIcon: Icon(Icons.lan),
            ),
            enabled: !config.overrides.contains('host'),
            autofocus: true,
            autocorrect: false,
            keyboardType: TextInputType.url,
            initialValue: config.host,
            onChanged: (value) => context.read<DbController>().host = value,
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),
          TextFormField(
            decoration: const InputDecoration(
              label: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: 'Port '),
                    TextSpan(
                      text: '*',
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
              hint: Text('5432'),
              prefixIcon: Icon(Icons.cable),
            ),
            enabled: !config.overrides.contains('port'),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            keyboardType: TextInputType.number,
            initialValue: config.port == 0 ? '' : config.port.toString(),
            onChanged: (value) =>
                context.read<DbController>().port = int.tryParse(value) ?? 0,
            validator: (value) => value?.isEmpty ?? true
                ? 'Required'
                : (int.tryParse(value!) ?? 0) == 0
                ? 'Invalid Port'
                : null,
          ),
          TextFormField(
            decoration: const InputDecoration(
              label: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: 'Datbase Name '),
                    TextSpan(
                      text: '*',
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
              hint: Text('phylum'),
              prefixIcon: Icon(Icons.storage),
            ),
            enabled: !config.overrides.contains('name'),
            autocorrect: false,
            initialValue: config.name,
            onChanged: (value) => context.read<DbController>().name = value,
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),
          TextFormField(
            decoration: const InputDecoration(
              label: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: 'User '),
                    TextSpan(
                      text: '*',
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
              hint: Text('phylum'),
              prefixIcon: Icon(Icons.person),
            ),
            enabled: !config.overrides.contains('user'),
            autocorrect: false,
            initialValue: config.user,
            onChanged: (value) => context.read<DbController>().user = value,
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),
          TextFormField(
            decoration: const InputDecoration(
              label: Text('Password'),
              prefixIcon: Icon(Icons.password),
            ),
            enabled: !config.overrides.contains('password'),
            autocorrect: false,
            obscureText: true,
            initialValue: config.password,
            onChanged: (value) => context.read<DbController>().password = value,
            onFieldSubmitted: (_) => validateAndNext(context),
          ),
        ],
      ),
    );
  }

  Future<void> validateAndNext(BuildContext context) async {
    final config = _bloc.validate();
    if (config == null) return;

    final nav = Navigator.of(context);
    showProgressDialog(context, message: 'Checking Email Config');
    final result = await _bloc.checkConfig(config);
    nav.pop();

    if (!context.mounted) return;

    switch (result) {
      case DbConfigCheckSuccess():
        onNextPress();
      case DbConfigCheckWarningNotEmpty():
        final response = await showAlertDialog(
          context,
          title: 'Warning',
          message: "The database is not empty.",
          positiveText: 'Continue anyway',
          negativeText: 'Wipe Data',
        );
        if (response == null) return;
        if (!response) {
          config.set(DbConfigFields.fieldWipe, true);
        }
        onNextPress();
      case DbConfigCheckFailed():
        final remain = await showAlertDialog(
          context,
          title: 'Config Check Failed',
          message: result.error,
          negativeText: 'Continue Anyway',
        );
        if (remain == false) {
          onNextPress();
        }
      case DbConfigCheckError():
        final remain = await showAlertDialog(
          context,
          title: result.title,
          message: result.message,
          negativeText: 'Continue Anyway',
        );
        if (remain == false) {
          onNextPress();
        }
      case DbConfigCheckUnknownWarning():
        final remain = await showAlertDialog(
          context,
          title: 'Warning',
          message:
              'The server returned a warning when trying to check the configuration.\n\n'
              'Warning code: ${result.code}',
          negativeText: 'Continue Anyway',
        );
        if (remain == false) {
          onNextPress();
        }
    }
  }
}

class DbController extends StateNotifier<DbConfig> {
  DbController(Set<String> overrides) : super(DbConfig(overrides));

  set host(String value) {
    state = state.copyWith(host: value);
  }

  set port(int value) {
    state = state.copyWith(port: value);
  }

  set name(String value) {
    state = state.copyWith(name: value);
  }

  set user(String value) {
    state = state.copyWith(user: value);
  }

  set password(String value) {
    state = state.copyWith(password: value);
  }

  set wipe(bool value) {
    state = state.copyWith(wipe: value);
  }
}

class DbConfig {
  final Set<String> overrides;
  final String host;
  final int port;
  final String name;
  final String user;
  final String password;
  final bool wipe;

  const DbConfig._({
    required this.overrides,
    required this.host,
    required this.port,
    required this.name,
    required this.user,
    required this.password,
    required this.wipe,
  });

  DbConfig(Set<String> overrides)
    : this._(
        overrides: overrides,
        host: 'localhost',
        port: 5432,
        name: 'phylum',
        user: 'phylum',
        password: '',
        wipe: false,
      );

  DbConfig copyWith({
    String? host,
    int? port,
    String? name,
    String? user,
    String? password,
    bool? wipe,
  }) {
    return DbConfig._(
      overrides: overrides,
      host: host ?? this.host,
      port: port ?? this.port,
      name: name ?? this.name,
      user: user ?? this.user,
      password: password ?? this.password,
      wipe: wipe ?? this.wipe,
    );
  }

  Map<String, dynamic> configToMap() {
    final map = {
      'host': host,
      'port': port,
      'name': name,
      'user': user,
      'password': password,
    };
    map.removeWhere((k, v) => overrides.contains(k));
    return map;
  }

  Map<String, dynamic> optionsToMap() {
    return {'wipe': true};
  }
}
