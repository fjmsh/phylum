import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:phylum/util/dialogs.dart';
import 'package:phylum/util/request.dart';
import 'package:uri/uri.dart';

Future<Pbkdf2Config?> configurePbkdf2(
  BuildContext context,
  Pbkdf2Config config,
  String instanceUrl,
) async {
  var iterations = config.iterations;
  var hash = config.hash;
  return showDialog<Pbkdf2Config>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text('PBKDF2 Parameters'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('Hash Function'),
              subtitle: Text(hash.descriptor),
              onTap: () async {
                final input = await showOptionsDialog(context, [
                  HashFunction.sha1,
                  HashFunction.sha256,
                  HashFunction.sha512,
                ], (item) => ListTile(title: Text(item.descriptor)));
                if (input != null) {
                  setState(() => hash = input);
                }
              },
            ),
            ListTile(
              title: Text('Iterations'),
              subtitle: Text(iterations.toString()),
              onTap: () async {
                final input = await showIntSliderDialog(
                  context,
                  title: 'Iterations',
                  value: iterations,
                  min: 200000,
                  max: 4000000,
                  divisionsFactor: 200000,
                );
                if (input != null) {
                  setState(() => iterations = input);
                }
              },
            ),
            ElevatedButton(
              onPressed: () =>
                  testPbkdf2Params(context, hash, iterations, instanceUrl),
              child: Text('Test Parameters'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(
              context,
            ).pop(Pbkdf2Config(hash: hash, iterations: iterations)),
            child: Text('OK'),
          ),
        ],
      ),
    ),
  );
}

Future<void> testPbkdf2Params(
  BuildContext context,
  HashFunction hash,
  int iterations,
  String instanceUrl,
) async {
  final builder = UriBuilder.fromUri(Uri.parse(instanceUrl));
  builder.path = '${builder.path}/api/v1/setup/auth/test_pbkdf2_params';
  builder.queryParameters = {
    "function": hash.name,
    "iterations": iterations.toString(),
  };
  final request = Request('get', builder.build());

  final responseString = await sendRequestDialog(
    context,
    request,
    message: 'Testing PBKDF2 Params',
  );
  if (responseString == null || !context.mounted) return;
  final responseMap = (jsonDecode(responseString) as Map)
      .cast<String, dynamic>();

  if (responseMap["success"]) {
    final time = Duration(microseconds: responseMap["time"]);
    await showAlertDialog(
      context,
      title:
          'Took ${time.inMilliseconds > 5 ? '${time.inMilliseconds}ms' : '${time.inMicroseconds}us'}',
      message: time.inMilliseconds < 300
          ? 'You should aim to take at least 300ms.'
          : time.inMilliseconds > 1000
          ? 'That\'s a long time. Consider lowering the number of iterations.'
          : 'Looks good!',
    );
  } else {
    await showAlertDialog(
      context,
      title: 'Could not test PBKDF2 params',
      message: "${responseMap["error"]}",
    );
  }
}

class Pbkdf2Config {
  final int iterations;
  final HashFunction hash;

  const Pbkdf2Config({required this.iterations, required this.hash});

  const Pbkdf2Config.defaults()
    : this(iterations: 600_000, hash: HashFunction.sha256);

  Map<String, dynamic> toMap() {
    return {'hash': hash.name, 'iterations': iterations};
  }

  @override
  String toString() {
    return 'hash=${hash.descriptor},iterations=$iterations';
  }
}

enum HashFunction {
  sha1('sha-1', 'SHA-1'),
  sha256('sha-256', 'SHA-256'),
  sha512('sha-512', 'SHA-512');

  final String name;
  final String descriptor;

  const HashFunction(this.name, this.descriptor);
}
