part of 'parsers.dart';

Iterable<Publink>? parsePublinks(List? data, String? root) {
  return data?.map((e) => parsePublink(e.cast(), root: root));
}

Publink parsePublink(Map<String, dynamic> data, {String? root}) {
  return Publink(
    id: data['id'],
    created: data['created'] == null ? null : DateTime.fromMillisecondsSinceEpoch(data['created']),
    root: root ?? data['root'],
    accessLimit: data['access_limit'],
    protected: data['protected'],
    accessed: data['accessed'],
    expires: data['expires'] == null ? null : DateTime.fromMillisecondsSinceEpoch(data['expires']),
  );
}
