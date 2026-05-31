import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:phylum/util/dialogs.dart';
import 'package:phylum/util/file_size.dart';
import 'package:phylum/util/request.dart';
import 'package:uri/uri.dart';

Future<Argon2Config?> configureArgon2(
  BuildContext context,
  Argon2Config config,
  String instanceUrl,
) async {
  int m = config.memory;
  int p = config.parallelism;
  int t = config.iterations;
  return showDialog<Argon2Config>(
      context: context,
      builder: (context) => StatefulBuilder(
            builder: (context, setState) => AlertDialog(
              title: Text('Argon2 Parameters'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: Text('Memory Factor'),
                    subtitle: Text(
                        '$m - ${pow(2, m + 10).toInt().formatForDisplay(noDecimal: true)}'),
                    onTap: () async {
                      final input = await showIntSliderDialog(context,
                          title: 'Memory Factor (m)',
                          value: m,
                          min: 10,
                          max: 24);
                      if (input != null) {
                        setState(() => m = input);
                      }
                    },
                  ),
                  ListTile(
                    title: Text('Parallelism'),
                    subtitle: Text(p.toString()),
                    onTap: () async {
                      final input = await showIntSliderDialog(context,
                          title: 'Parallelism (p)', value: p, min: 1, max: 8);
                      if (input != null) {
                        setState(() => p = input);
                      }
                    },
                  ),
                  ListTile(
                    title: Text('Iterations'),
                    subtitle: Text(t.toString()),
                    onTap: () async {
                      final input = await showIntSliderDialog(context,
                          title: 'Iterations (t)', value: t, min: 1, max: 20);
                      if (input != null) {
                        setState(() => t = input);
                      }
                    },
                  ),
                  ElevatedButton(
                      onPressed: () =>
                          testArgon2Params(context, m, t, p, instanceUrl),
                      child: Text('Test Parameters'))
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(context).pop(null),
                    child: Text('Cancel')),
                ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(
                        Argon2Config(memory: m, parallelism: p, iterations: t)),
                    child: Text('OK')),
              ],
            ),
          ));
}

Future<void> testArgon2Params(
  BuildContext context,
  int memory,
  int iterations,
  int parallelism,
  String instanceUrl,
) async {
  final builder = UriBuilder.fromUri(Uri.parse(instanceUrl));
  builder.path = '${builder.path}/api/v1/setup/auth/test_argon2_params';
  builder.queryParameters = {
    "memory": memory.toString(),
    "iterations": iterations.toString(),
    "parallelism": parallelism.toString(),
  };
  final request = Request('get', builder.build());

  final responseString =
      await sendRequest(context, 'Testing Argon2 Params', request);
  if (responseString == null || !context.mounted) return;
  final responseMap =
      (jsonDecode(responseString) as Map).cast<String, dynamic>();

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
    await showAlertDialog(context,
        title: 'Could not test argon2 params',
        message: "${responseMap["error"]}");
  }
}

class Argon2Config {
  final int memory;
  final int parallelism;
  final int iterations;

  const Argon2Config(
      {required this.memory,
      required this.parallelism,
      required this.iterations});

  const Argon2Config.defaults()
      : this(memory: 16, parallelism: 2, iterations: 4);

  Map<String, dynamic> toMap() {
    return {
      'memory': memory,
      'parallelism': parallelism,
      'iterations': iterations,
    };
  }

  @override
  String toString() {
    return 'm=$memory,t=$iterations,p=$parallelism';
  }
}
