import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phylum/ui/settings/auth/form/ldap_config_cubit.dart';

class LdapConfigForm extends StatelessWidget {
  final LdapConfigCubit _bloc;
  const LdapConfigForm({super.key, required this._bloc});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 12,
      children: [
        BlocBuilder<LdapConfigCubit, LdapConfigState>(
          bloc: _bloc,
          builder: (context, state) => TextFormField(
            decoration: InputDecoration(
              label: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: 'LDAP Server URL '),
                    if (!state.isServerUrlFixed())
                      TextSpan(
                        text: '*',
                        style: TextStyle(color: Colors.red),
                      ),
                  ],
                ),
              ),
              prefixIcon: Icon(Icons.lan),
              errorText: state.serverUrlError,
              hint: Text('ldap://ldap.example.com:389'),
            ),
            keyboardType: TextInputType.url,
            initialValue: state.serverUrl,
            onChanged: (value) => _bloc.serverUrl = value,
          ),
        ),
        BlocBuilder<LdapConfigCubit, LdapConfigState>(
          bloc: _bloc,
          builder: (context, state) => SwitchListTile(
            value: state.starttls,
            title: const Text('Use STARTTLS'),
            secondary: Icon(Icons.lock),
            onChanged: state.isStarttlsFixed()
                ? null
                : (value) => _bloc.starttls = value,
          ),
        ),
        BlocBuilder<LdapConfigCubit, LdapConfigState>(
          bloc: _bloc,
          builder: (context, state) => SwitchListTile(
            value: state.useFilter,
            title: const Text('Search for DN'),
            subtitle: Text('For converting email to DN'),
            onChanged: state.isUseFilterFixed()
                ? null
                : (value) => _bloc.useFilter = value,
          ),
          buildWhen: (previous, current) =>
              previous.useFilter != current.useFilter,
        ),
        BlocBuilder<LdapConfigCubit, LdapConfigState>(
          bloc: _bloc,
          builder: (context, state) => state.useFilter
              ? DnFilterInputField(bloc: _bloc)
              : DnTemplateInputField(bloc: _bloc),
          buildWhen: (previous, current) =>
              previous.useFilter != current.useFilter,
        ),
        BlocBuilder<LdapConfigCubit, LdapConfigState>(
          bloc: _bloc,
          builder: (context, state) => SwitchListTile(
            value: state.autoCreateUsers,
            title: Text('Auto-create Accounts'),
            onChanged: (value) => _bloc.autoCreateUsers = value,
          ),
        ),
      ],
    );
  }
}

class DnTemplateInputField extends StatelessWidget {
  final LdapConfigCubit _bloc;
  const DnTemplateInputField({super.key, required this._bloc});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LdapConfigCubit, LdapConfigState>(
      bloc: _bloc,
      builder: (context, state) {
        return TextFormField(
          decoration: InputDecoration(
            label: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: 'DN Template '),
                  TextSpan(
                    text: '*',
                    style: TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
            hint: Text('uid={email},ou=people,dc=example,dc=com'),
            errorText: state.dnTemplateError,
          ),
          initialValue: state.dnTemplate,
          key: ValueKey('dn_template'),
          onChanged: (value) => _bloc.dnTemplate = value,
        );
      },
    );
  }
}

class DnFilterInputField extends StatelessWidget {
  final LdapConfigCubit _bloc;
  const DnFilterInputField({super.key, required this._bloc});

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 12.0,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextFormField(
          decoration: InputDecoration(
            label: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: 'Bind DN'),
                  TextSpan(
                    text: '*',
                    style: TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
            hint: Text('uid=phylum,ou=people,dc=example,dc=com'),
            errorText: _bloc.state.filterBindDnError,
          ),
          key: ValueKey('bindDn'),
          initialValue: _bloc.state.filterBindDn,
          onChanged: (value) => _bloc.filterBindDn = value,
        ),
        TextFormField(
          decoration: const InputDecoration(label: Text('Bind Password')),
          obscureText: true,
          key: ValueKey('bindPassword'),
          onChanged: (value) => _bloc.filterBindPassword = value,
        ),
        TextFormField(
          decoration: InputDecoration(
            label: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: 'Base DN'),
                  TextSpan(
                    text: '*',
                    style: TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
            hint: Text('dc=example,dc=com'),
            errorText: _bloc.state.filterBaseDnError,
          ),
          key: ValueKey('baseDn'),
          initialValue: _bloc.state.filterBaseDnError,
          onChanged: (value) => _bloc.filterBaseDn = value,
        ),
        TextFormField(
          decoration: InputDecoration(
            label: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: 'Filter Template'),
                  TextSpan(
                    text: '*',
                    style: TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
            hint: Text('(mail={email})'),
            errorText: _bloc.state.filterTemplateError,
          ),
          initialValue: _bloc.state.filterTemplate,
          key: ValueKey('filterTemplate'),
          onChanged: (value) => _bloc.filterBindPassword = value,
        ),
      ],
    );
  }
}
