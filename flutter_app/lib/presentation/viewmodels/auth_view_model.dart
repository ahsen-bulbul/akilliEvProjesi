import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../domain/repositories/auth_repository.dart';

class AuthViewModel extends ChangeNotifier {
  AuthViewModel(this._repository) {
    _user = _repository.currentUser;
    _repository.authStateChanges.listen((user) {
      _user = user;
      notifyListeners();
    });
  }

  final AuthRepository _repository;

  User? _user;
  bool _loading = false;
  String? _error;

  User? get user => _user;
  bool get loading => _loading;
  String? get error => _error;
  bool get isSignedIn => _user != null;

  Future<void> ensureAnonymousSession() async {
    if (_repository.currentUser != null) {
      return;
    }
    await _run(() => _repository.signInAnonymously());
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _run(
      () => _repository.signInWithEmail(email: email, password: password),
    );
  }

  Future<void> registerWithEmail({
    required String email,
    required String password,
  }) {
    return _run(
      () => _repository.registerWithEmail(email: email, password: password),
    );
  }

  Future<void> signOut() {
    return _run(_repository.signOut);
  }

  Future<void> _run(Future<void> Function() action) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await action();
    } on FirebaseAuthException catch (e) {
      _error = e.message ?? e.code;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
