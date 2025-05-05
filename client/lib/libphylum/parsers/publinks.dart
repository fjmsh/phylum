part of 'parsers.dart';

Iterable<Publink> parsePublinks(List data, String? root) {
  return data.cast<Map>().map((e) => parsePublink(e, root: root));
}

Publink parsePublink(Map data, {String? root}) {
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
