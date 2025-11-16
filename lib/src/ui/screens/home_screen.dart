import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/i18n.dart';
import '../../models/meal_log.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../services/user_service.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/nutrition_card.dart';

class HomeScreen extends StatefulWidget {
  static const route = '/home';
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0;
  final _userService = UserService();
  List<MealLog> _meals = [];
  bool _loadingMeals = false;
  String? _error;
  String? _loadedUserId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = Provider.of<AuthProvider>(context);
    final currentUserId = auth.user?.id;
    if (currentUserId != null && currentUserId != _loadedUserId) {
      _loadedUserId = currentUserId;
      _loadMeals();
    }
  }

  Future<void> _loadMeals() async {
    final AppUser? user = context.read<AuthProvider>().user;
    if (user == null) return;

    setState(() {
      _loadingMeals = true;
      _error = null;
    });

    try {
      final meals =
          await _userService.fetchMeals(user.id, date: DateTime.now());
      setState(() {
        _meals = meals;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loadingMeals = false;
      });
    }
  }

  double get _totalCalories =>
      _meals.fold(0, (value, meal) => value + meal.totalCalories);
  double get _totalProtein =>
      _meals.fold(0, (value, meal) => value + meal.totalProtein);
  double get _totalCarbs =>
      _meals.fold(0, (value, meal) => value + meal.totalCarbs);
  double get _totalFat =>
      _meals.fold(0, (value, meal) => value + meal.totalFat);

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final auth = context.watch<AuthProvider>();
    final AppUser? user = auth.user;

    if (user == null) {
      return const SizedBox.shrink();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(t.t('home_title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadMeals,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            NutritionCard(
              calories: _totalCalories,
              protein: _totalProtein,
              carbs: _totalCarbs,
              fat: _totalFat,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/meal/add').then((_) {
                    _loadMeals();
                  });
                },
                icon: const Icon(Icons.add),
                label: Text(t.t('add_meal')),
              ),
            ),
            if (_loadingMeals) const LinearProgressIndicator(),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Erro ao carregar refei\u00e7\u00f5es: $_error',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            if (!_loadingMeals && _meals.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Nenhuma refei\u00e7\u00e3o registrada hoje.'),
              ),
            ..._meals.map(
              (meal) => ListTile(
                title: Text('${meal.totalCalories.toStringAsFixed(0)} kcal'),
                subtitle: Text('Fonte: ${meal.source}'),
                trailing: Text(meal.date),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      bottomNavigationBar: BottomNav(
        currentIndex: _tabIndex,
        onTap: (i) {
          setState(() {
            _tabIndex = i;
          });
          switch (i) {
            case 1:
              Navigator.pushNamed(context, '/stats');
              break;
            case 2:
              Navigator.pushNamed(context, '/profile');
              break;
            case 3:
              Navigator.pushNamed(context, '/community');
              break;
            default:
              break;
          }
        },
      ),
    );
  }
}
