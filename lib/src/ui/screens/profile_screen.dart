import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/i18n.dart';
import '../../providers/auth_provider.dart';
import '../../services/gamification_service.dart';
import '../../models/gamification_summary.dart';
import 'profile_goals_screen.dart';

class ProfileScreen extends StatefulWidget {
  static const route = '/profile';
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  GamificationSummary? _summary;
  bool _loading = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadGamification();
  }

  Future<void> _loadGamification() async {
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final service = GamificationService();
      final summary = await service.getSummary(user.id);
      setState(() {
        _summary = summary;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.t('profile_title')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (user != null) ...[
              Text(user.name ?? user.email,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(user.email),
            ],
            const SizedBox(height: 24),

            if (_loading) const LinearProgressIndicator(),
            if (_error != null) Text('Erro: $_error'),

            if (_summary != null) ...[
              Card(
                child: ListTile(
                  leading: const Icon(Icons.star),
                  title: const Text('Pontos'),
                  subtitle: Text('${_summary!.points} pontos totais'),
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.local_fire_department),
                  title: const Text('Streak'),
                  subtitle: Text(
                      'Atual: ${_summary!.streak.current} dias • Melhor: ${_summary!.streak.best}'),
                ),
              ),
              const SizedBox(height: 8),
              Text('Conquistas:',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              if (_summary!.achievements.isEmpty)
                const Text('Nenhuma conquista ainda. Continue registrando!'),
              if (_summary!.achievements.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _summary!.achievements
                      .map((a) => Chip(
                            label: Text(_mapAchievementLabel(a)),
                          ))
                      .toList(),
                ),
            ],
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.favorite, color: Color(0xFFA8D0E6)),
                title: const Text('Minhas Metas'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pushNamed(context, ProfileGoalsScreen.route);
                },
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () => auth.signOut(),
              child: Text(t.t('logout')),
            ),
          ],
        ),
      ),
    );
  }

  String _mapAchievementLabel(String code) {
    switch (code) {
      case 'first_meal':
        return 'Primeira refeição 🎉';
      case 'first_photo_meal':
        return 'Primeira refeição por foto 📸';
      case 'streak_7':
        return '7 dias seguidos 🔥';
      case 'streak_30':
        return '30 dias seguidos 👑';
      default:
        return code;
    }
  }
}
