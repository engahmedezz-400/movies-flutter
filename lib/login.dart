import 'package:flutter_bloc/flutter_bloc.dart';
import 'features/account/data/firebase_account_repository.dart';
import 'features/account/presentation/account_cubit.dart';
import 'reset_password.dart';
import 'package:flutter/material.dart';
import 'profile_avatars.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  final name = TextEditingController();
  final confirmation = TextEditingController();
  final phone = TextEditingController();
  int avatar = 0;
  bool showConfirmation = false;
  bool register = false;
  final account = AccountCubit(FirebaseAccountRepository());

  @override
  void dispose() {
    account.close();
    name.dispose();
    confirmation.dispose();
    phone.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    final messenger = ScaffoldMessenger.of(context);
    final warning = label('Account created. Some profile details could not be saved.',
        'تم إنشاء الحساب وتعذر حفظ بعض بيانات الملف الشخصي');
    final complete = await account.submit(registering: register, email: email.text.trim(),
        password: password.text, confirmation: confirmation.text, name: name.text.trim(),
        phone: phone.text.trim(), avatar: avatar, arabic: arabic);
    if (complete == false && messenger.mounted) {
      messenger.showSnackBar(SnackBar(content: Text(warning)));
    }
  }

  bool arabic = false;
  bool showPassword = false;
  static const gold = Color(0xffffbb3b);

  String label(String en, String ar) => arabic ? ar : en;

  InputDecoration field(String hint, IconData icon, {Widget? end}) {
    return InputDecoration(hintText: hint, prefixIcon: Icon(icon), suffixIcon: end,
      filled: true, fillColor: const Color(0xff303030),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none));
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<AccountCubit, AccountState>(bloc: account, builder: (context, state) {
    final busy = state.busy;
    final message = state.message;
    final title = register ? label('Create account', 'إنشاء حساب') : label('Login', 'دخول');
    final button = FilledButton.styleFrom(backgroundColor: gold, foregroundColor: Colors.black,
      minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)));
    return Directionality(textDirection: arabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(backgroundColor: const Color(0xff191919), body: SafeArea(child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 32), children: [
          if (register) ...[
            Stack(alignment: Alignment.center, children: [
              Align(alignment: AlignmentDirectional.centerStart, child: BackButton(color: gold,
                onPressed: busy ? null : () => setState(() { register = false; account.clear(); }))),
              Text(label('Register', 'إنشاء حساب'), style: const TextStyle(color: gold)),
            ]),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              for (final offset in [-1, 0, 1])
                Flexible(child: Semantics(button: offset != 0, label: '${label('Avatar', 'الصورة')} ${((avatar + offset) % profileAvatars.length) + 1}',
                  child: GestureDetector(onTap: busy || offset == 0 ? null : () => setState(() {
                    avatar = (avatar + offset) % profileAvatars.length;
                  }), child: ClipOval(child: Image.memory(profileAvatars[(avatar + offset) % profileAvatars.length],
                    width: offset == 0 ? 132 : 78, gaplessPlayback: true))))),
            ]),
            Center(child: Text(label('Avatar', 'الصورة الشخصية'))),
            const SizedBox(height: 12),
            TextField(controller: name, decoration: field(label('Name', 'الاسم'), Icons.badge_outlined)),
            const SizedBox(height: 16),
          ] else const Padding(padding: EdgeInsets.only(top: 16, bottom: 40),
            child: Icon(Icons.play_circle_outline_rounded, color: gold, size: 110)),
          TextField(controller: email, keyboardType: TextInputType.emailAddress,
            decoration: field(label('Email', 'البريد الإلكتروني'), Icons.email)),
          const SizedBox(height: 16),
          TextField(controller: password, obscureText: !showPassword,
            decoration: field(label('Password', 'كلمة المرور'), Icons.lock,
              end: IconButton(icon: Icon(showPassword ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() { showPassword = !showPassword; })))),
          if (register) ...[
            const SizedBox(height: 16),
            TextField(controller: confirmation, obscureText: !showConfirmation,
              decoration: field(label('Confirm Password', 'تأكيد كلمة المرور'), Icons.lock,
                end: IconButton(icon: Icon(showConfirmation ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() { showConfirmation = !showConfirmation; })))),
            const SizedBox(height: 16),
            TextField(controller: phone, keyboardType: TextInputType.phone,
              decoration: field(label('Phone Number', 'رقم الموبايل'), Icons.phone)),
          ],
          if (!register) Align(alignment: AlignmentDirectional.centerEnd, child: TextButton(
            onPressed: busy ? null : () => Navigator.push<void>(context, MaterialPageRoute(
              builder: (_) => ResetPasswordPage(address: email.text.trim(), arabic: arabic))),
            child: Text(label('Forget Password ?', 'نسيت كلمة المرور؟'), style: const TextStyle(color: gold)))),
          const SizedBox(height: 12),
          FilledButton(style: button, onPressed: busy ? null : submit, child: Text(busy ? '…' : title)),
          TextButton(onPressed: busy ? null : () => setState(() { register = !register; account.clear(); }),
            child: Text(register ? label('Already registered? Login', 'عندك حساب؟ دخول') :
              label("Don’t Have Account ? Create One", 'معندكش حساب؟ أنشئ حساب'), style: const TextStyle(color: gold))),
          if (!register) ...[
            Row(children: [const Expanded(child: Divider(color: gold)), Padding(padding: const EdgeInsets.all(12),
              child: Text(label('OR', 'أو'))), const Expanded(child: Divider(color: gold))]),
            FilledButton.icon(style: button, onPressed: busy ? null : () => account.google(arabic),
              icon: const Text('G', style: TextStyle(fontWeight: FontWeight.bold)),
              label: Text(label('Login With Google', 'الدخول باستخدام Google'))),
          ],
          Center(child: TextButton(onPressed: busy ? null : () => setState(() { arabic = !arabic; }),
            child: Text(arabic ? 'English' : 'العربية', style: const TextStyle(color: gold)))),
          if (message.isNotEmpty) Text(message),
        ],
      ))));
  });
}
