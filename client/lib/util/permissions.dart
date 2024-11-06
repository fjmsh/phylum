import 'dart:convert';

typedef Permission = int;

const Permission PermissionRead = 4;
const Permission PermissionWrite = 32;
const Permission PermissionShare = 128;

Map<String, Permission> calculatePermissionSet(Iterable<String?> permissionJsons) {
  final permissions = <String, Permission>{};
  for (final p in permissionJsons) {
    if (p == null) continue;
    for (final e in (jsonDecode(p) as Map).cast<String, Permission>().entries) {
      permissions[e.key] = (permissions[e.key] ?? 0) | e.value;
    }
  }
  return permissions;
}

extension PermissionStringer on Permission {
  String toStringFull() {
    if (this == 0) return "None";
    if (this == -1) return "All";

    final b = StringBuffer();
    int p = this;
    if (p & PermissionRead != 0) {
      p -= PermissionRead;
      b.write('Read');
    }
    if (p & PermissionWrite != 0) {
      p -= PermissionWrite;
      if (b.isNotEmpty) {
        b.write(', ');
      }
      b.write('Write');
    }
    if (p & PermissionShare != 0) {
      p -= PermissionShare;
      if (b.isNotEmpty) {
        b.write(', ');
      }
      b.write('Share');
    }
    return b.toString();
  }

  String toStringShort() {
    if (this == 0) return "x";
    if (this == -1) return "su";

    String r = '';
    int p = this;
    if (p & PermissionRead != 0) {
      r += 'r';
      p -= PermissionRead;
    }
    if (p & PermissionWrite != 0) {
      r += 'w';
      p -= PermissionWrite;
    }
    if (p & PermissionShare != 0) {
      r += 's';
      p -= PermissionShare;
    }
    return r;
  }
}
