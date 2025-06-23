import 'package:flutter/material.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/requests/set_cookie_request.dart';
import 'package:phylum/libphylum/responses/responses.dart';
import 'package:provider/provider.dart';
import 'package:web/web.dart' as web;

Future<bool> downloadResource(BuildContext context, Resource r, {ResourceVersion? version}) async {
  final apiClient = context.read<PhylumAccount>().apiClient;
  final success = await apiClient
      .sendRequest(const SetCookieRequest(), (_, response) => parseEmptyResponse(response))
      .then((result) => result is ApiSuccessResponse);
  if (!success) {
    return false;
  }
  final uri = apiClient.createUriBuilder('/api/v1/fs/contents/${r.id}:');
  uri.queryParameters['download'] = '';
  if (version != null) {
    uri.queryParameters['version'] = version.id;
  }
  web.HTMLAnchorElement()
    ..target = '_blank'
    ..href = uri.toString()
    ..download = version == null ? r.name : '${r.name}-${version.created.toIso8601String()}'
    ..click();
  return true;
}

class DownloadManager with ChangeNotifier {
  Future<void> downloadResource(PhylumAccount account, Resource r, {String? versionId}) async {}
}
