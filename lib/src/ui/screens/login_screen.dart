import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/i18n.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  static const route = '/auth/login';
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(t.t('login_title')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
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
                      await auth.signIn(
                          _emailCtrl.text.trim(), _passwordCtrl.text.trim());
                    },
              child: auth.loading
                  ? const CircularProgressIndicator()
                  : Text(t.t('login')),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/auth/signup');
              },
              child: Text(t.t('signup')),
            )
          ],
        ),
      ),
    );
  }
}
