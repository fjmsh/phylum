import 'package:flutter/material.dart';
import 'package:phylum/ui/settings/auth/form/ldap_config_cubit.dart';

class LdapConfigForm extends StatelessWidget {
  final LdapConfigCubit _bloc;
  const LdapConfigForm({super.key, required this._bloc});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text('LDAP Configuration'),
      leading: Icon(Icons.storage),
    );
  }
}
