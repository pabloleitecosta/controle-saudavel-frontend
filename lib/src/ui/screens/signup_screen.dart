import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/i18n.dart';
import '../../providers/auth_provider.dart';

class SignupScreen extends StatefulWidget {
  static const route = '/auth/signup';
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(t.t('signup_title')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(labelText: t.t('name')),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailCtrl,
              decoration: InputDecoration(labelText: t.t('email')),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordCtrl,
              decoration: InputDecoration(labelText: t.t('password')),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: auth.loading
                  ? null
                  : () async {
                      await auth.signUp(
                        _nameCtrl.text.trim(),
                        _emailCtrl.text.trim(),
                        _passwordCtrl.text.trim(),
                      );
                      if (mounted) {
                        Navigator.pop(context);
                      }
                    },
              child: auth.loading
                  ? const CircularProgressIndicator()
                  : Text(t.t('signup')),
            ),
          ],
        ),
      ),
    );
  }
}
