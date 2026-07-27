import 'package:phylum/ui/settings/config/remote_config.dart';

class LocalConfigUpdates<C extends ConfigFields> {
  final Map<FieldDef, dynamic> updates = {};

  LocalConfigUpdates();

  void set<T>(FieldDef<T> field, T value) {
    updates[field] = value;
  }

  T get<T>(FieldDef<T> field) {
    return updates[field] ?? field.defaultValue;
  }

  Map<String, dynamic> toMapDiff(RemoteConfig<C> remote) {
    final result = <String, dynamic>{};
    for (final entry in updates.entries) {
      final remoteValue = remote.values[entry.key];
      if (remoteValue == entry.value || remoteValue?.fixed == true) continue;

      String path = entry.key.path;
      Map<String, dynamic> map = result;
      while (path.contains(".")) {
        final i = path.indexOf(".");
        final key = path.substring(0, i);
        if (map[key] == null) {
          final m = <String, dynamic>{};
          map[key] = m;
          map = m;
        } else if (map[key] is Map<String, dynamic>) {
          map = map[key];
        } else {}
        path = path.substring(i + 1);
      }
      map[path] = entry.value?.value;
    }
    return result;
  }
}
