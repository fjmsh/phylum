import 'package:flutter/material.dart';
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: () => createKey(context),
          label: Text('Generate New API Key'),
          icon: Icon(Icons.add),
        ),
        for (final k in keys)
          Card(
            margin: EdgeInsets.all(2.0),
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    k.description,
                    style: const TextStyle(fontSize: 18),
                  ),
                  Text('Created ${k.created.formatLong()}', style: const TextStyle(fontSize: 15)),
                  Text('Expires ${k.expires?.formatLong() ?? 'Never'}', style: const TextStyle(fontSize: 15)),
                  Text('Scopes: ${k.scopes.join(', ')}', style: const TextStyle(fontSize: 15)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void fetchKeys(BuildContext context) async {
    final account = context.read<PhylumAccount>();
    final response = await account.apiClient.sendRequest(
      const ListApiKeysRequest(),
      (request, response) => parseJsonListResponse(response, ListApiKeysResponse.fromResponse),
    );

    if (response is ListApiKeysResponse) {
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
