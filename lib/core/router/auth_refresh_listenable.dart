import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthRefreshListenable extends ChangeNotifier {
  String? _lastUserId;

  AuthRefreshListenable() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user?.uid != _lastUserId) {
        _lastUserId = user?.uid;
        notifyListeners();
      }
    });
  }
}
