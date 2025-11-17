import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  static const route = '/auth/signup';
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final platform = Theme.of(context).platform;
    final supportsApple =
        platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;

    return Scaffold(
      appBar: AppBar(title: const Text('Criar conta')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nome'),
            ),
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(labelText: 'E-mail'),
            ),
            TextField(
              controller: passCtrl,
              decoration: const InputDecoration(labelText: 'Senha'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: auth.loading
                  ? null
                  : () async {
                      final ok = await auth.signup(
                        nameCtrl.text.trim(),
                        emailCtrl.text.trim(),
                        passCtrl.text.trim(),
                      );
                      if (ok && mounted) {
                        Navigator.pushReplacementNamed(context, '/home');
                      }
                    },
              child: auth.loading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Criar conta'),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: auth.loading
                  ? null
                  : () async {
                      final ok = await auth.loginWithGoogle();
                      if (ok && mounted) {
                        Navigator.pushReplacementNamed(context, '/home');
                      }
                    },
              icon: const Icon(Icons.login),
              label: const Text('Cadastrar com Google'),
            ),
            const SizedBox(height: 12),
            if (supportsApple)
              ElevatedButton.icon(
                onPressed: auth.loading
                    ? null
                    : () async {
                        final ok = await auth.loginWithApple();
                        if (ok && mounted) {
                          Navigator.pushReplacementNamed(context, '/home');
                        }
                      },
                icon: const Icon(Icons.apple),
                label: const Text('Cadastrar com Apple'),
              ),
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.pushReplacementNamed(
                  context, LoginScreen.route),
              child: const Text('Ja tem conta? Entrar'),
            ),
          ],
        ),
      ),
    );
  }
}
