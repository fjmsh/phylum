import 'package:flutter/material.dart';
import 'package:moment_dart/moment_dart.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/requests/api_key_generate_request.dart';
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
                    ? Text('Unnamed', style: TextStyle(fontStyle: FontStyle.italic))
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Key Details'),
        content: ListTileTheme(
          data: ListTileThemeData(visualDensity: VisualDensity.adaptivePlatformDensity),
          child: Column(
            children: [
              ListTile(title: const Text('ID'), subtitle: Text(key.id)),
              ListTile(
                title: const Text('Description'),
                subtitle: Text(key.description),
                trailing: IconButton(onPressed: () {}, icon: Icon(Icons.edit)),
              ),
              ListTile(title: const Text('Created'), subtitle: Text(key.created.fromNow())),
              ListTile(
                  title:
                      (key.expires?.isBefore(DateTime.now()) ?? false) ? const Text('Expired') : const Text('Expires'),
                  subtitle: key.expires == null
                      ? const Text('Never')
                      : Text('${key.expires!.fromNow()} (${key.expires!.formatShort()})')),
              ListTile(title: const Text('Scopes'), subtitle: Text(key.scopes.join(', '))),
              ListTile(
                title: const Text('Last Used'),
                subtitle: key.lastUsed.used
                    ? Text('${key.lastUsed.device} \u2022 ${key.lastUsed.ip} \u2022 ${key.lastUsed.fromNow()}')
                    : const Text('Never Used'),
              ),
            ],
          ),
        ),
        scrollable: true,
        actions: [
          ElevatedButton(
              onPressed: () {},
              child: Text('Delete Key', style: TextStyle(color: Theme.of(context).colorScheme.error))),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(), child: Text('OK')),
        ],
      ),
    );
  }

  void fetchKeys(BuildContext context) async {
    final account = context.read<PhylumAccount>();
    final response = await account.apiClient.sendRequest(
      const ListApiKeysRequest(),
      (request, response) => parseJsonListResponse(response, ListApiKeysResponse.fromResponse),
    );

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
    final response = await account.apiClient.sendRequest(
        GenerateApiKeyRequest(
          description: k.description,
          expires: k.expires,
          scopes: k.scopes,
        ),
        (_, response) => parseJsonMapResponse(response, GenerateApiKeyResponse.fromResponse));

    if (response is GenerateApiKeyResponse) {
      if (!context.mounted) return;
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
                        decoration: InputDecoration(label: Text('Key ID')),
                        initialValue: response.keyId,
                        readOnly: true,
                      ),
                      TextFormField(
                        decoration: InputDecoration(label: Text('Key')),
                        initialValue: response.key,
                        readOnly: true,
                      ),
                      TextFormField(
                        decoration: InputDecoration(label: Text('Access Token')),
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
