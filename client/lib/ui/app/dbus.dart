import 'dart:io';

import 'package:dbus/dbus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:phylum/util/logging/logging.dart';
import 'package:window_manager/window_manager.dart';

const dbusName = String.fromEnvironment(
  "DBUS_NAME",
  defaultValue: "cloud.phylum.drive",
);

void ensureSingleClientDBus() async {
  final sessionClient = DBusClient.session();
  final requestReply = await sessionClient.requestName(
    dbusName,
    flags: {DBusRequestNameFlag.doNotQueue},
  );
  if (requestReply == DBusRequestNameReply.primaryOwner) {
    await sessionClient.registerObject(InstanceObject());
  } else if (requestReply == DBusRequestNameReply.exists) {
    Log.info('Instance Already Running');
    final object = DBusRemoteObject(
      sessionClient,
      name: dbusName,
      path: DBusObjectPath('/Instance'),
    );

    try {
      var value = await object.getProperty(
        dbusName,
        'Version',
        signature: DBusSignature('s'),
      );
      var version = value.asString();
      Log.info('Version $version');
    } catch (e) {
      Log.warn('DBus Exception. Version Unknown', e);
    }

    try {
      await object.callMethod(
        dbusName,
        'Show',
        [],
        replySignature: DBusSignature(''),
      );
      await sessionClient.close();
    } catch (e) {
      Log.warn('DBus Exception. Could not call "show"', e);
    } finally {
      exit(0);
    }
  } else {
    throw StateError('Unsupported DBus Name Request Reply: $requestReply');
  }
}

class InstanceObject extends DBusObject {
  InstanceObject() : super(DBusObjectPath('/Instance'));

  @override
  Future<DBusMethodResponse> getProperty(String interface, String name) async {
    if (interface == dbusName) {
      if (name == 'Version') {
        final version = await PackageInfo.fromPlatform()
            .then((info) => info.version)
            .onError((err, stack) => 'DEV');
        return DBusGetPropertyResponse(DBusString(version));
      } else {
        return DBusMethodErrorResponse.unknownProperty();
      }
    } else {
      return DBusMethodErrorResponse.unknownInterface();
    }
  }

  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall methodCall) async {
    if (methodCall.interface == dbusName) {
      if (methodCall.name == 'Show') {
        if (methodCall.signature != DBusSignature('')) {
          return DBusMethodErrorResponse.invalidArgs();
        }
        windowManager.focus();

        return DBusMethodSuccessResponse([]);
      } else {
        return DBusMethodErrorResponse.unknownMethod();
      }
    } else {
      return DBusMethodErrorResponse.unknownInterface();
    }
  }
}
