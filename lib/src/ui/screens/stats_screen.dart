import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/i18n.dart';
import '../../models/user_insights.dart';
import '../../providers/auth_provider.dart';
import '../../services/user_service.dart';

class StatsScreen extends StatefulWidget {
  static const route = '/stats';
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final _userService = UserService();
  Future<UserInsights>? _future;
  String? _lastUserId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = Provider.of<AuthProvider>(context);
    final userId = auth.user?.id;
    if (userId != null && userId != _lastUserId) {
      _lastUserId = userId;
      _future = _userService.fetchInsights(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.t('stats_title')),
      ),
      body: _future == null
          ? const Center(
              child: Text('Entre com sua conta para ver os insights.'),
            )
          : FutureBuilder<UserInsights>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Erro ao carregar insights: ${snapshot.error}'),
                    ),
                  );
                }
                final insights = snapshot.data!;
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.fastfood),
                        title: const Text('M\u00e9dia cal\u00f3rica'),
                        subtitle: Text(
                            '${insights.avgCalories.toStringAsFixed(0)} kcal'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.fitness_center),
                        title: const Text('M\u00e9dia proteica'),
                        subtitle: Text(
                            '${insights.avgProtein.toStringAsFixed(1)} g'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.restaurant),
                        title: const Text('Refei\u00e7\u00f5es analisadas'),
                        subtitle: Text('${insights.mealsCount} refei\u00e7\u00f5es'),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Insights da semana',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (insights.insights.isEmpty)
                      const Text(
                        'Ainda n\u00e3o h\u00e1 recomenda\u00e7\u00f5es. Registre suas refei\u00e7\u00f5es para gerar dicas personalizadas.',
                      )
                    else
                      ...insights.insights.map(
                        (text) => ListTile(
                          leading: const Icon(Icons.insights),
                          title: Text(text),
                        ),
                      ),
                  ],
                );
              },
            ),
    );
  }
}
