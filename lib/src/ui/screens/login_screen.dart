import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  static const route = '/auth/login';
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final platform = Theme.of(context).platform;
    final supportsApple =
        platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;

    return Scaffold(
      appBar: AppBar(title: const Text("Entrar")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(labelText: "E-mail"),
            ),
            TextField(
              controller: passCtrl,
              decoration: const InputDecoration(labelText: "Senha"),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: auth.loading
                  ? null
                  : () async {
                      final ok = await auth.loginWithEmail(
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
                  : const Text("Entrar"),
            ),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),
            // ---- GOOGLE ----
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
              label: const Text("Entrar com Google"),
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
                label: const Text("Entrar com Apple"),
              ),
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.pushReplacementNamed(
                  context, SignupScreen.route),
              child: const Text("Criar conta"),
            ),
          ],
        ),
      ),
    );
  }
}
