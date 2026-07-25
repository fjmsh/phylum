import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/responses/responses.dart';
import 'package:phylum/util/logging/logging.dart';
import 'package:phylum/util/request.dart';
import 'package:provider/provider.dart';

import '../login_controller.dart';

Future<void> login(BuildContext context, BaseRequest request) async {
  final result = await sendRequest(request);
  if (!context.mounted) return;
  if (result is! SuccessResponse) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result.toString())));
    return;
  }
  final accountManager = context.read<AccountManager<PhylumAccount>>();
  try {
    final response = BootstrapLoginResponse.fromResponse(
      (jsonDecode(result.responseString) as Map).cast<String, dynamic>(),
    );
    final instanceUrl = context.read<LoginState>().instanceUrl!;
    final account = await PhylumAccount.create(
      serverUrl: instanceUrl,
      apiToken: response.apiToken!,
      user: response.user,
      config: response.config,
    );
    await response.process(account);
    await accountManager.addAccount(account);
  } catch (e, stack) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error Parsing Response - $e')));
    }
    Log.warn('Error Parsing Response', e, stack);
  }
}
