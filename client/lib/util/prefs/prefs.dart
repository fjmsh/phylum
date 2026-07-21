import 'package:shared_preferences/shared_preferences.dart';

abstract class Prefs {
  static late final SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static SharedPreferences get() {
    return _prefs;
  }
}
