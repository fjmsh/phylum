import 'package:shared_preferences/shared_preferences.dart';

bool _init = false;
late final SharedPreferences? _prefs;

abstract class Prefs {
  static Future<SharedPreferences> get() async {
    if (!_init) {
      _prefs = await SharedPreferences.getInstance();
      _init = true;
    }
    return _prefs!;
  }
}
