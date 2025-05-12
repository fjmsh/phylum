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

extension PermissionMapper on String? {
  Map<String, Permission> parsePermissionMap() =>
      this == null ? {} : (jsonDecode(this!) as Map).cast<String, Permission>();

  // Map<String, Permission> parseGrantsMap() => this == null
  //     ? {}
  //     : Map.fromEntries((jsonDecode(this!) as Map)
  //         .cast<String, Map>()
  //         .entries
  //         .map((e) => MapEntry(e.key, e.value.cast<String, int>()['p']!)));
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
