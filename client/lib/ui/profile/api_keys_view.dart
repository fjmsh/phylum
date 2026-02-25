import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:moment_dart/moment_dart.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/requests/api_key_edit_request.dart';
import 'package:phylum/libphylum/requests/api_key_generate_request.dart';
import 'package:phylum/libphylum/requests/api_key_revoke_request.dart';
import 'package:phylum/libphylum/requests/api_keys_list_request.dart';
import 'package:phylum/libphylum/responses/responses.dart';
import 'package:phylum/ui/profile/generate_api_key_dialog.dart';
import 'package:phylum/util/dialogs.dart';
import 'package:phylum/util/time.dart';
import 'package:provider/provider.dart';

class ApiKeysView extends StatefulWidget {
  const ApiKeysView({super.key});

  @override
  State<ApiKeysView> createState() => _ApiKeysViewState();
}

class _ApiKeysViewState extends State<ApiKeysView> {
  String? error;
  List<ApiKey>? keys;

  @override
  void initState() {
    super.initState();
    fetchKeys(context);
  }

  @override
  Widget build(BuildContext context) {
    final keys = this.keys;

    if (keys == null) {
      return Center(
        child: error == null ? const CircularProgressIndicator() : Text(error!),
      );
    }

    return ListTileTheme(
      data: ListTileThemeData(
        tileColor: Theme.of(context).colorScheme.surfaceBright,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: ElevatedButton.icon(
              onPressed: () => createKey(context),
              label: Text('Generate New API Key'),
              icon: Icon(Icons.add),
            ),
          ),
          ...ListTile.divideTiles(context: context, tiles: [
            for (final k in keys)
              ListTile(
                title: k.description.isEmpty
                    ? const Text('No Description', style: TextStyle(fontStyle: FontStyle.italic))
                    : Text(k.description),
                subtitle: k.lastUsed.used
                    ? Text('${k.lastUsed.device} \u2022 ${k.lastUsed.fromNow()}')
                    : const Text('Never Used'),
                onTap: () => _showKeyDetails(context, k),
              ),
          ]),
        ],
      ),
    );
  }

  void _showKeyDetails(BuildContext context, ApiKey key) async {
    final account = context.read<PhylumAccount>();
    String desc = key.description;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Key Details'),
        content: ListTileTheme(
          data: ListTileThemeData(visualDensity: VisualDensity.adaptivePlatformDensity),
          child: Column(
            children: [
              ListTile(
                title: const Text('ID'),
                subtitle: Text(key.id),
                trailing: IconButton(
                    onPressed: () => Clipboard.setData(ClipboardData(text: key.id)), icon: const Icon(Icons.copy)),
              ),
              StatefulBuilder(builder: (context, ss) {
                return ListTile(
                  title: const Text('Description'),
                  subtitle: desc.isEmpty
                      ? const Text('No Description', style: TextStyle(fontStyle: FontStyle.italic))
                      : Text(desc),
                  trailing: IconButton(
                      onPressed: () async {
                        final nav = Navigator.of(context);
                        final description = await showInputDialog(
                          context,
                          title: 'Key Description',
                          preset: desc,
                          hintText: 'No Description',
                        );
                        if (description == null || !context.mounted) return;

                        showProgressDialog(context);
                        final result = await account.apiClient
                            .sendRequest(EditApiKeyRequest(id: key.id, description: description));
                        nav.pop();
                        if (result is ApiSuccessResponse) {
                          if (context.mounted) {
                            ss(() => desc = description);
                            setState(() => keys![keys!.indexOf(key)] = key.copyWith(description: description));
                          }
                        } else {
                          if (context.mounted) {
                            await showAlertDialog(context,
                                title: 'Unable to delete API Key', message: result.description);
                          }
                        }
                      },
                      icon: Icon(Icons.edit)),
                );
              }),
              ListTile(title: const Text('Created'), subtitle: Text(key.created.fromNow())),
              ListTile(
                  title:
                      (key.expires?.isBefore(DateTime.now()) ?? false) ? const Text('Expired') : const Text('Expires'),
                  subtitle: key.expires == null
                      ? const Text(
                          'Never',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        )
                      : Text('${key.expires!.fromNow()} (${key.expires!.formatShort()})')),
              ListTile(title: const Text('Scopes'), subtitle: Text(key.scopes.join(', '))),
              ListTile(
                title: const Text('Last Used'),
                subtitle: key.lastUsed.used
                    ? Text('${key.lastUsed.device} \u2022 ${key.lastUsed.ip} \u2022 ${key.lastUsed.fromNow()}')
                    : const Text(
                        'Never',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
              ),
            ],
          ),
        ),
        scrollable: true,
        actions: [
          ElevatedButton(
              onPressed: () async {
                final nav = Navigator.of(context);
                showProgressDialog(context);
                final result = await account.apiClient.sendRequest(RevokeApiKeyRequest(id: key.id, delete: true));
                nav.pop();
                if (result is ApiSuccessResponse) {
                  if (context.mounted) {
                    await showAlertDialog(context, title: 'API Key Deleted');
                    nav.pop();
                    setState(() => keys?.removeWhere((k) => k == key));
                  }
                } else {
                  if (context.mounted) {
                    await showAlertDialog(context, title: 'Unable to delete API Key', message: result.description);
                  }
                }
              },
              child: Text('Delete Key', style: TextStyle(color: Theme.of(context).colorScheme.error))),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(), child: Text('OK')),
        ],
      ),
    );
  }

  void fetchKeys(BuildContext context) async {
    final account = context.read<PhylumAccount>();
    final response = await account.apiClient.sendRequest(const ListApiKeysRequest());

    if (response is ListApiKeysResponse) {
      response.keys.sort((a, b) {
        if (a.lastUsed.timestamp == b.lastUsed.timestamp) {
          b.created.compareTo(a.created);
        }
        return b.lastUsed.timestamp - a.lastUsed.timestamp;
      });
      setState(() => keys = response.keys);
    } else {
      setState(() => error = response.description);
    }
  }

  void createKey(BuildContext context) async {
    final account = context.read<PhylumAccount>();
    final k = await GenerateApiKeyDialog.show(context);
    if (k == null) return;
    final response = await account.apiClient.sendRequest(GenerateApiKeyRequest(
      description: k.description,
      expires: k.expires,
      scopes: k.scopes,
    ));

    if (response is GenerateApiKeyResponse) {
      if (!context.mounted) return;

      final key = ApiKey(
        created: Moment.now(),
        expires: k.expires?.toMoment(),
        id: response.keyId,
        description: k.description,
        scopes: k.scopes,
        lastUsed: LastUsedInfo(0, '', ''),
      );
      setState(() => keys = keys == null ? [key] : [...keys!, key]);
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title: Text('API Key Generated'),
                content: SizedBox(
                  width: 480,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6.0),
                        child: Text('Key ID and Key can be used as the username and password in HTTP Basic auth'),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6.0),
                        child:
                            Text('Access Token can be used as a Bearer token, or with HTTP Basic auth by leaving the '
                                'username empty'),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6.0),
                        child: Text(
                            'Please note down the details as it will not be possible to retreive once it is dismissed.'),
                      ),
                      TextFormField(
                        decoration: InputDecoration(
                          label: Text('Key ID'),
                          suffixIcon: IconButton(
                              onPressed: () => Clipboard.setData(ClipboardData(text: response.keyId)),
                              icon: Icon(Icons.copy)),
                        ),
                        initialValue: response.keyId,
                        readOnly: true,
                      ),
                      TextFormField(
                        decoration: InputDecoration(
                          label: Text('Key'),
                          suffixIcon: IconButton(
                              onPressed: () => Clipboard.setData(ClipboardData(text: response.key)),
                              icon: Icon(Icons.copy)),
                        ),
                        initialValue: response.key,
                        readOnly: true,
                      ),
                      TextFormField(
                        decoration: InputDecoration(
                          label: Text('Access Token'),
                          suffixIcon: IconButton(
                              onPressed: () => Clipboard.setData(ClipboardData(text: response.accessToken)),
                              icon: Icon(Icons.copy)),
                        ),
                        initialValue: response.accessToken,
                        readOnly: true,
                      ),
                    ],
                  ),
                ),
                actions: [
                  ElevatedButton(onPressed: () => Navigator.of(context).pop(), child: Text('OK')),
                ],
              ));
    } else {
      if (!context.mounted) return;
      showAlertDialog(context, title: 'Error Generating API Key', message: response.description);
    }
  }
}

extension on LastUsedInfo {
  String fromNow() {
    if (timestamp == 0) {
      return "Never";
    }
    return Moment.fromMillisecondsSinceEpoch(timestamp * 1000).fromNow();
  }

  bool get used => timestamp != 0;
}
