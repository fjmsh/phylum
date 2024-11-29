import 'dart:convert';

typedef Permission = int;

const Permission permissionRead = 4;
const Permission permissionWrite = 32;
const Permission permissionShare = 128;

const Permission permissionSetNone = 0;
const Permission permissionSetAll = -1;
const Permission permissionSetReadOnly = permissionRead;
const Permission permissionSetReadWrite = permissionRead | permissionWrite;
const Permission permissionSetReadWriteShare = permissionRead | permissionWrite | permissionShare;

Map<String, Permission> calculatePermissionSet(Iterable<String?> permissionJsons) {
  final permissions = <String, Permission>{};
  for (final p in permissionJsons) {
    mergePermissions(permissions, p);
  }
  return permissions;
}

Map<String, Permission> mergePermissions(Map<String, Permission> permissions, String? permissionsJson) {
  if (permissionsJson != null) {
    for (final e in (jsonDecode(permissionsJson) as Map).cast<String, Permission>().entries) {
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
    if (p & permissionRead != 0) {
      p -= permissionRead;
      b.write('Read');
    }
    if (p & permissionWrite != 0) {
      p -= permissionWrite;
      if (b.isNotEmpty) {
        b.write(', ');
      }
      b.write('Write');
    }
    if (p & permissionShare != 0) {
      p -= permissionShare;
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
    if (p & permissionRead != 0) {
      r += 'r';
      p -= permissionRead;
    }
    if (p & permissionWrite != 0) {
      r += 'w';
      p -= permissionWrite;
    }
    if (p & permissionShare != 0) {
      r += 's';
      p -= permissionShare;
    }
    return r;
  }
}
