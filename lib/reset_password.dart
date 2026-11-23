import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ResetPasswordPage extends StatefulWidget {
  final String address;
  final bool arabic;
  const ResetPasswordPage({super.key, required this.address, required this.arabic});
  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  late final email = TextEditingController(text: widget.address);
  bool sending = false;
  String message = '';
  String label(String en, String ar) => widget.arabic ? ar : en;

  @override
  void dispose() {
    email.dispose();
    super.dispose();
  }

  Future<void> send() async {
    if (sending) return;
    final address = email.text.trim();
    if (address.isEmpty) {
      setState(() { message = label('Enter your email first.', 'اكتب بريدك الإلكتروني أولًا'); });
      return;
    }
    setState(() { sending = true; message = ''; });
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: address);
      if (mounted) setState(() { message = label('Check your inbox and spam folder for the reset link.', 'راجع بريدك ومجلد الرسائل غير المرغوب فيها للعثور على رابط الاستعادة'); });
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() { message = e.message ?? e.code; });
    } catch (_) {
      if (mounted) setState(() { message = label('Could not send. Try again.', 'تعذّر الإرسال. حاول مرة أخرى'); });
    } finally {
      if (mounted) setState(() { sending = false; });
    }
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: widget.arabic ? TextDirection.rtl : TextDirection.ltr,
    child: Scaffold(backgroundColor: const Color(0xff191919),
      appBar: AppBar(centerTitle: true, foregroundColor: Colors.amber,
        title: Text(label('Forget Password', 'استعادة كلمة المرور'))),
      body: SafeArea(child: ListView(padding: const EdgeInsets.all(18), children: [
        const Padding(padding: EdgeInsets.symmetric(vertical: 55),
          child: Icon(Icons.lock_reset_rounded, size: 140, color: Colors.amber)),
        TextField(controller: email, enabled: !sending, keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done, onSubmitted: (_) => send(),
          decoration: InputDecoration(filled: true, prefixIcon: const Icon(Icons.email),
            labelText: label('Email', 'البريد الإلكتروني'),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)))),
        const SizedBox(height: 16),
        FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black,
          minimumSize: const Size.fromHeight(52)), onPressed: sending ? null : send,
          child: Text(sending ? '…' : label('Verify Email', 'إرسال رابط الاستعادة'))),
        if (message.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 16), child: Text(message)),
      ])),
    ));
}
