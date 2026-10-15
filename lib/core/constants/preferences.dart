import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:doctro/core/constants/prefConstatnt.dart';

class SharedPreferenceHelper {
  static Future<SharedPreferences> get _instance async =>
      _preferences ??= await SharedPreferences.getInstance();

  static SharedPreferences? _preferences;
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static Map<String, String> _secureCache = {};

  static const List<String> _sensitiveKeys = [
    Preferences.auth_token,
    Preferences.refresh_token,
    Preferences.password,
  ];

  // call this method from iniState() function of mainApp().
  static Future<SharedPreferences?> init() async {
    _preferences = await _instance;
    return initWithPreferences(_preferences!);
  }

  static Future<SharedPreferences?> initWithPreferences(
      SharedPreferences preferences) async {
    _preferences = preferences;
    Future<void>(() async {
      try {
        _secureCache = await _secureStorage.readAll();

        // Migrate sensitive data from SharedPreferences to SecureStorage if it exists.
        for (String key in _sensitiveKeys) {
          if (_preferences!.containsKey(key) &&
              !_secureCache.containsKey(key)) {
            String? val = _preferences!.getString(key);
            if (val != null) {
              await _secureStorage.write(key: key, value: val);
              _secureCache[key] = val;
              await _preferences!.remove(key);
            }
          }
        }
      } catch (e) {
        // Handle potential platform exception on first run or corrupt keystore.
        _secureCache = {};
      }
    });
    return _preferences;
  }

  static bool _isSensitive(String key) => _sensitiveKeys.contains(key);

  //sets
  static Future<bool> setBoolean(String key, bool value) async =>
      await _preferences!.setBool(key, value);

  static Future<bool> setDouble(String key, double value) async =>
      await _preferences!.setDouble(key, value);

  static Future<bool> setInt(String key, int value) async =>
      await _preferences!.setInt(key, value);

  static Future<bool> setString(String key, String value) async {
    if (_isSensitive(key)) {
      await _secureStorage.write(key: key, value: value);
      _secureCache[key] = value;
      return true;
    }
    return await _preferences!.setString(key, value);
  }

  static Future<bool> setStringList(String key, List<String> value) async =>
      await _preferences!.setStringList(key, value);

  //gets
  static bool getBoolean(String key) => _preferences!.getBool(key) ?? false;

  static double getDouble(String key) => _preferences!.getDouble(key) ?? 0.0;

  static int getInt(String key) => _preferences!.getInt(key) ?? 0;

  static String getString(String key) {
    if (_isSensitive(key)) {
      return _secureCache[key] ?? 'N_A';
    }
    return _preferences?.getString(key) ?? 'N_A';
  }

  /// Like [getString] but returns null when the key was never written,
  /// instead of the legacy 'N_A' sentinel. Prefer this wherever "absent"
  /// is meaningful, so callers don't have to compare against a magic string.
  static String? getStringOrNull(String key) {
    final value = getString(key);
    if (value.isEmpty || value == 'N_A') return null;
    return value;
  }

  static List<String> getStringList(String key) =>
      _preferences!.getStringList(key) ?? [];

  //deletes..
  static Future<bool> remove(String key) async {
    if (_isSensitive(key)) {
      await _secureStorage.delete(key: key);
      _secureCache.remove(key);
      return true;
    }
    return await _preferences!.remove(key);
  }

  static Future<void> clearPref() async {
    await _preferences!.clear();
    await _secureStorage.deleteAll();
    _secureCache.clear();
  }
}
