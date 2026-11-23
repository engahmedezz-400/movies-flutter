class AccountFailure implements Exception {
  final String message;
  const AccountFailure(this.message);
}

abstract interface class AccountRepository {
  Future<void> login(String email, String password);
  Future<bool> register(String email, String password, String name, String phone, int avatar);
  Future<void> google();
  Future<void> update(String uid, String name, String phone, int? avatar);
}
