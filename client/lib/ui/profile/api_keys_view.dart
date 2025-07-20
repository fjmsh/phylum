import 'package:flutter/material.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/requests/api_keys_request.dart';
import 'package:phylum/libphylum/responses/responses.dart';
import 'package:phylum/ui/profile/generate_api_key_dialog.dart';
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
      const ApiKeysRequest(),
      (request, response) => parseJsonListResponse(response, ApiKeysResponse.fromResponse),
    );

    if (response is ApiKeysResponse) {
      setState(() => keys = response.keys);
    } else {
      setState(() => error = response.description);
    }
  }

  void createKey(BuildContext context) async {
    GenerateApiKeyDialog.show(context);
  }
}
