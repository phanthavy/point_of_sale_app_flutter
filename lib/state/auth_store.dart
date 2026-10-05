import 'package:client/data/sample_data.dart';
import 'package:client/models/user.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthStore extends ChangeNotifier {
  static const _storageKey = 'logged_in_username';

  AppUser? _user;
  SharedPreferences? _prefs;

  AppUser? get user => _user;

  /// Restores the last logged-in user, if any.
  void attach(SharedPreferences prefs) {
    _prefs = prefs;
    final username = prefs.getString(_storageKey);
    for (final user in users) {
      if (user.username == username) _user = user;
    }
  }

  bool login(String username, String password) {
    final name = username.trim().toLowerCase();
    for (final user in users) {
      if (user.username == name && user.password == password) {
        _user = user;
        _prefs?.setString(_storageKey, user.username);
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  void logout() {
    _user = null;
    _prefs?.remove(_storageKey);
    notifyListeners();
  }
}

final authStore = AuthStore();
