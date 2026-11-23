import 'package:flutter_bloc/flutter_bloc.dart';
import '../domain/account_repository.dart';

class AccountState {
  final bool busy;
  final String message;
  const AccountState({this.busy = false, this.message = ''});
}

class AccountCubit extends Cubit<AccountState> {
  final AccountRepository repository;
  AccountCubit(this.repository) : super(const AccountState());
  static final _phone = RegExp(r'^\+?[0-9]{7,15}$');

  void clear() {
    if (!state.busy) emit(const AccountState());
  }

  Future<T?> _run<T>(Future<T> Function() action, String fallback) async {
    if (state.busy) return null;
    emit(const AccountState(busy: true));
    try {
      final value = await action();
      if (!isClosed) emit(const AccountState());
      return value;
    } catch (error) {
      if (!isClosed) {
        emit(AccountState(message: error is AccountFailure ? error.message : fallback));
      }
      return null;
    }
  }

  Future<bool?> submit({required bool registering, required String email, required String password,
      required String confirmation, required String name, required String phone,
      required int avatar, required bool arabic}) async {
    if (state.busy) return null;
    String label(String en, String ar) => arabic ? ar : en;
    String error = '';
    if (email.isEmpty || password.isEmpty) {
      error = label('Enter your email and password.', 'اكتب البريد الإلكتروني وكلمة المرور');
    } else if (registering && name.isEmpty) {
      error = label('Enter your name.', 'اكتب اسمك');
    } else if (registering && password != confirmation) {
      error = label('Passwords do not match.', 'كلمتا المرور غير متطابقتين');
    } else if (registering && !_phone.hasMatch(phone)) {
      error = label('Enter 7 to 15 digits, with an optional +.', 'اكتب من ٧ إلى ١٥ رقمًا ويمكن إضافة + في البداية');
    }
    if (error.isNotEmpty) {
      emit(AccountState(message: error));
      return null;
    }
    return _run<bool>(() async {
      if (registering) return repository.register(email, password, name, phone, avatar);
      await repository.login(email, password);
      return true;
    }, label('Could not reach Firebase. Try again.', 'تعذّر الاتصال. حاول مرة أخرى'));
  }

  Future<void> google(bool arabic) async {
    await _run<void>(repository.google, arabic ? 'حاول مرة أخرى' : 'Please try again.');
  }

  Future<bool> update(String uid, String name, String phone, int? avatar) async {
    if (state.busy) return false;
    if (name.isEmpty || (phone.isNotEmpty && !_phone.hasMatch(phone))) {
      emit(const AccountState(message: 'Enter your name. Phone is optional (7–15 digits).'));
      return false;
    }
    return await _run<bool>(() async {
      await repository.update(uid, name, phone, avatar);
      return true;
    }, 'Could not save your profile. Try again.') ?? false;
  }
}
