import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/account_repository.dart';

class FirebaseAccountRepository implements AccountRepository {
  Future<T> _auth<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on FirebaseAuthException catch (error) {
      throw AccountFailure(error.message ?? error.code);
    }
  }

  Future<void> _store(String uid, String name, String phone, int? avatar) =>
      SharedPreferencesAsync().setStringList('profile.$uid', [name, phone, avatar?.toString() ?? '']);

  @override
  Future<void> login(String email, String password) async {
    await _auth(() => FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password));
  }

  @override
  Future<bool> register(String email, String password, String name, String phone, int avatar) async {
    final account = await _auth(() => FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password));
    final user = account.user!;
    try {
      await _store(user.uid, name, phone, avatar);
      await user.updateDisplayName(name);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> google() async {
    await _auth(() => FirebaseAuth.instance.signInWithProvider(GoogleAuthProvider()));
  }

  @override
  Future<void> update(String uid, String name, String phone, int? avatar) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.uid != uid) {
      throw const AccountFailure('Please sign in again.');
    }
    if (user.displayName != name) {
      await _auth(() => user.updateDisplayName(name));
    }
    try {
      await _store(uid, name, phone, avatar);
    } catch (_) {
      throw const AccountFailure('Name saved. Retry to save phone and avatar on this device.');
    }
  }
}
