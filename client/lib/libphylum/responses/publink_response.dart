part of 'responses.dart';

class PublinkResponse extends PhylumApiSuccessResponse {
  final Publink publink;

  PublinkResponse({required this.publink});

  factory PublinkResponse.fromResponse(Map<String, dynamic> data) {
    final publink = parsePublink((data as Map).cast<String, dynamic>());
    return PublinkResponse(publink: publink);
  }

  @override
  Future<void> process(PhylumAccount account) async {
    await account.db.publinks.insertOne(
      publink,
      mode: InsertMode.insertOrReplace,
    );
    await account.datastore.get<Publink>().replaceRemoteData(
      publink.id,
      publink,
    );
  }
}
