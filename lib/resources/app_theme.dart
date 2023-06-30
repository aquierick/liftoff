import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppTheme extends ChangeNotifier {
  final String themeKey = 'theme';
  final String amoledKey = 'amoled';
  final String primaryKey = 'primary';

  SharedPreferences? _prefs;
  late bool _amoled;
  late ThemeMode _theme;
  late Color _primaryColor;

  bool get amoled => _amoled;
  ThemeMode get theme => _theme;
  Color get primaryColor => _primaryColor;

  AppTheme() {
    _theme = ThemeMode.system;
    _loadprefs();
  }

  switchtheme(ThemeMode theme) {
    _theme = theme;
    if (theme != ThemeMode.dark) {
      _amoled = false;
    }
    _saveprefs();
    notifyListeners();
  }

  switchamoled() {
    _amoled = true;
    switchtheme(ThemeMode.dark);
    _saveprefs();
    notifyListeners();
  }

  setPrimaryColor(Color color) {
    _primaryColor = color;
    _saveprefs();
    notifyListeners();
  }

  _initiateprefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  _loadprefs() async {
    await _initiateprefs();
    _theme = ThemeMode.values[_prefs?.getInt(themeKey) ?? 0];
    _amoled = _prefs?.getBool(amoledKey) ?? false;

    final defaultPrimary = _theme == ThemeMode.light
        ? ThemeData().primaryColorLight
        : ThemeData().primaryColorDark;
    _primaryColor = Color(_prefs?.getInt(primaryKey) ?? defaultPrimary.value);

    notifyListeners();
  }

  _saveprefs() async {
    await _initiateprefs();
    await _prefs?.setInt(themeKey, _theme.index);
    await _prefs?.setBool(amoledKey, _amoled);
    await _prefs?.setInt(primaryKey, _primaryColor.value);
  }
}
