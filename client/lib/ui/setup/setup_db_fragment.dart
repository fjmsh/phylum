import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phylum/ui/setup/setup_fragment.dart';

class SetupDbFragment extends SetupFragment<SetupDbFragment> {
  const SetupDbFragment({super.key});

  @override
  SetupFragmentState<SetupDbFragment> createState() => SetupDbFragmentState();
}

class SetupDbFragmentState extends SetupFragmentState<SetupDbFragment> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 24, right: 24, bottom: 8.0),
          child: TextField(
            decoration: const InputDecoration(label: Text('Host'), hint: Text('localhost')),
            autofocus: true,
            autocorrect: false,
            keyboardType: TextInputType.url,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 24, right: 24, bottom: 8.0),
          child: TextField(
            decoration: const InputDecoration(label: Text('Port'), hint: Text('5432')),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            keyboardType: TextInputType.number,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 24, right: 24, bottom: 8.0),
          child: TextField(
            decoration: const InputDecoration(label: Text('Database Name'), hint: Text('phylum')),
            autocorrect: false,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 24, right: 24, bottom: 8.0),
          child: TextField(
            decoration: const InputDecoration(label: Text('User'), hint: Text('phylum')),
            autocorrect: false,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 24, right: 24, bottom: 8.0),
          child: TextField(
            decoration: const InputDecoration(label: Text('Password')),
            autocorrect: false,
            obscureText: true,
          ),
        ),
      ],
    );
  }

  @override
  bool handleNextPress() {
    print('Next Press');
    return true;
  }
}

class DbConfig {
  final String host;
  final int port;
  final String dbName;
  final String user;
  final String password;

  DbConfig({
    required this.host,
    required this.port,
    required this.dbName,
    required this.user,
    required this.password,
  });
}
