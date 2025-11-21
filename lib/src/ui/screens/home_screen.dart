import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/meal_log.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../services/user_service.dart';
import '../widgets/add_food_modal.dart';
import 'add_meal_manual_screen.dart';
import 'profile_goals_screen.dart';

class HomeScreen extends StatefulWidget {
  static const route = "/home";
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final softBlue = const Color(0xFFA8D0E6);
  final darkText = const Color(0xFF0F172A);
  final UserService _userService = UserService();
  final DateFormat _dateFormatter = DateFormat('yyyy-MM-dd');

  bool _loadingMeals = false;
  Map<String, List<MealLog>> _mealsByDay = {};
  late List<DateTime> _weekDays;
  int selectedDay = DateTime.now().weekday - 1; // 0 = segunda

  @override
  void initState() {
    super.initState();
    _initWeekDays();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMealsForWeek());
  }

  void _initWeekDays() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    _weekDays = List.generate(
      7,
      (index) => DateTime(
        startOfWeek.year,
        startOfWeek.month,
        startOfWeek.day + index,
      ),
    );
    if (selectedDay < 0 || selectedDay > 6) selectedDay = 0;
  }

  Future<void> _loadMealsForWeek() async {
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user == null) return;
    setState(() => _loadingMeals = true);
    try {
      final meals = await _userService.fetchMeals(user.id);
      final start = _weekDays.first;
      final end = _weekDays.last;
      final Map<String, List<MealLog>> grouped = {};

      for (final meal in meals) {
        DateTime? parsed;
        try {
          parsed = DateTime.parse(meal.date);
        } catch (_) {
          parsed = null;
        }
        if (parsed == null) continue;
        final day = DateTime(parsed.year, parsed.month, parsed.day);
        if (day.isBefore(start) || day.isAfter(end)) continue;
        final key = _dateFormatter.format(day);
        grouped.putIfAbsent(key, () => []).add(meal);
      }

      setState(() => _mealsByDay = grouped);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar refeições: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingMeals = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final AppUser? user = auth.user;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadMealsForWeek,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                _buildHeader(user),
                const SizedBox(height: 8),
                _buildWeeklyStreak(),
                const SizedBox(height: 10),
                _buildPlanCards(),
                const SizedBox(height: 12),
                _buildMacroBar(),
                const SizedBox(height: 16),
                _buildMealsSection(context),
                const SizedBox(height: 20),
                _buildPremiumOptions(context),
                const SizedBox(height: 25),
                _buildDailySummary(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // HEADER
  Widget _buildHeader(AppUser? user) {
    String time = DateFormat("HH:mm").format(DateTime.now());
    final name = (user?.name?.trim().isNotEmpty ?? false)
        ? user!.name!.trim()
        : (user?.email ?? "Usuario");

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(time,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: darkText,
              )),
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: softBlue,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : "U",
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.grey.shade200,
                child: Icon(Icons.notifications_none, color: darkText),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // WEEKLY STREAK
  Widget _buildWeeklyStreak() {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        itemBuilder: (_, i) {
          bool active = i == selectedDay;
          final day = _weekDays[i];
          final label = DateFormat('E', 'pt_BR')
              .format(day)
              .substring(0, 1)
              .toUpperCase();
          return GestureDetector(
            onTap: () => setState(() => selectedDay = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 60,
              height: 60,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: active ? softBlue : Colors.grey.shade300,
                  width: 3,
                ),
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: active ? softBlue : Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // PLAN CARDS (placeholder)
  Widget _buildPlanCards() {
    return SizedBox(
      height: 160,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _planCard("Jejum Intermitente", "2400 cal", Colors.red),
          _planCard("Cetogenico", "2000 cal", Colors.green),
          _planCard("Mediterraneo", "2400 cal", Colors.orange),
        ],
      ),
    );
  }

  Widget _planCard(String title, String cal, Color color) {
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Text(
          "$title\n$cal",
          style: const TextStyle(
            color: Color(0xFF1B1B1B),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // MACRO BAR
  Widget _buildMacroBar() {
    final dayMeals = _mealsForSelectedDay();
    final totalCalories =
        dayMeals.fold<double>(0, (sum, meal) => sum + meal.totalCalories);
    final totalProtein =
        dayMeals.fold<double>(0, (sum, meal) => sum + meal.totalProtein);
    final totalCarbs =
        dayMeals.fold<double>(0, (sum, meal) => sum + meal.totalCarbs);
    final totalFat =
        dayMeals.fold<double>(0, (sum, meal) => sum + meal.totalFat);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              blurRadius: 12,
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _macro("Gord", totalFat.toStringAsFixed(1)),
            _macro("Carb", totalCarbs.toStringAsFixed(1)),
            _macro("Prot", totalProtein.toStringAsFixed(1)),
            _macro("Cal", totalCalories.toStringAsFixed(0)),
          ],
        ),
      ),
    );
  }

  Widget _macro(String label, String value) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            )),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 16)),
      ],
    );
  }

  // MEALS SECTION
  Widget _buildMealsSection(BuildContext context) {
    final selectedDate = _weekDays[selectedDay];
    final dayLabel = DateFormat('EEEE, d MMM', 'pt_BR').format(selectedDate);

    const mealTypes = [
      'Café da manhã',
      'Almoço',
      'Jantar',
      'Lanches/Outros',
      'Personalizar Refeições',
      'Contador de água',
    ];

    final icons = <String, IconData>{
      'Café da manhã': Icons.wb_sunny_outlined,
      'Almoço': Icons.lunch_dining,
      'Jantar': Icons.nightlight_round,
      'Lanches/Outros': Icons.bedtime,
      'Personalizar Refeições': Icons.edit_note,
      'Contador de água': Icons.water_drop_outlined,
    };

    final dayMeals = _mealsForSelectedDay();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Hoje",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    dayLabel,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
              if (_loadingMeals)
                const CircularProgressIndicator(strokeWidth: 2),
            ],
          ),
          const SizedBox(height: 12),
          if (dayMeals.isEmpty && !_loadingMeals)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 10,
                    color: Colors.black.withOpacity(0.05),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Nenhuma refeição registrada ainda",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Toque em uma refeição para adicionar alimentos.",
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ...mealTypes.map(
            (type) => _mealCard(
              title: type,
              icon: icons[type] ?? Icons.restaurant_menu,
              meals: dayMeals
                  .where((m) => _canonicalType(m.mealType) == type)
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  List<MealLog> _mealsForSelectedDay() {
    final key = _dateFormatter.format(_weekDays[selectedDay]);
    return _mealsByDay[key] ?? [];
  }

  Widget _mealCard({
    required String title,
    required IconData icon,
    required List<MealLog> meals,
  }) {
    final totalCalories =
        meals.fold<double>(0, (sum, m) => sum + m.totalCalories);
    final totalProtein =
        meals.fold<double>(0, (sum, m) => sum + m.totalProtein);
    final totalCarbs = meals.fold<double>(0, (sum, m) => sum + m.totalCarbs);
    final totalFat = meals.fold<double>(0, (sum, m) => sum + m.totalFat);

    final allItems = meals.expand((m) => m.items).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            color: Colors.black.withOpacity(0.05),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: softBlue, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (meals.isNotEmpty)
                Text(
                  "${totalCalories.toStringAsFixed(0)} Calorias",
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
              IconButton(
                onPressed: () => _openAddFoodModal(context, title),
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _macro("Gord", totalFat.toStringAsFixed(1)),
              _macro("Carb", totalCarbs.toStringAsFixed(1)),
              _macro("Prot", totalProtein.toStringAsFixed(1)),
              _macro("Cal", totalCalories.toStringAsFixed(0)),
            ],
          ),
          if (allItems.isNotEmpty) const Divider(height: 16),
          if (allItems.isNotEmpty)
            ...allItems.map(
              (item) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(item.label),
                subtitle: Text(
                  "P ${item.protein.toStringAsFixed(1)}g · C ${item.carbs.toStringAsFixed(1)}g · G ${item.fat.toStringAsFixed(1)}g",
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                trailing: Text(
                  "${item.calories.toStringAsFixed(0)} kcal",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _openAddFoodModal(BuildContext context, String mealType) async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return AddFoodModal(mealType: mealType);
      },
    );

    if (result == true) {
      await _loadMealsForWeek();
    } else if (result is Map && result['manual'] == true) {
      final type = (result['mealType'] as String?) ?? mealType;
      final created = await Navigator.of(context).pushNamed(
        AddMealManualScreen.route,
        arguments: {'mealType': type},
      );
      if (created == true) {
        await _loadMealsForWeek();
      }
    }
  }

  // PREMIUM OPTIONS (placeholders)
  Widget _buildPremiumOptions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _optionCard("Minhas Metas de Saúde", "TMB, TDEE e metas nutricionais",
              Icons.favorite_border, () {
            Navigator.pushNamed(context, ProfileGoalsScreen.route);
          }),
          _optionCard("Comunidade", "Feed e gamificação", Icons.forum_outlined,
              () {
            Navigator.pushNamed(context, '/community');
          }),
          _optionCard("Contador de Água", "Hidratação diária",
              Icons.water_drop_outlined, () {}),
          _optionCard("Exercício e Sono", "Registre sua rotina",
              Icons.fitness_center, () {}),
        ],
      ),
    );
  }

  Widget _optionCard(
      String title, String sub, IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            color: Colors.black.withOpacity(0.05),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: softBlue, size: 30),
        title: Text(title,
            style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.w600, color: darkText)),
        subtitle: Text(sub,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
        trailing: Icon(Icons.chevron_right, color: Colors.grey.shade500),
      ),
    );
  }

  // DAILY SUMMARY (placeholder)
  Widget _buildDailySummary() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              blurRadius: 10,
              color: Colors.black.withOpacity(0.05),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Resumo diário",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: darkText)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text("Calorias Restantes"),
                Text("2800",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text("Calorias Consumidas"),
                Text("0",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _canonicalType(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('manhã') || lower.contains('manha')) {
      return 'Café da manhã';
    }
    if (lower.contains('almo')) return 'Almoço';
    if (lower.contains('jantar')) return 'Jantar';
    if (lower.contains('lanche') || lower.contains('snack')) {
      return 'Lanches/Outros';
    }
    if (lower.contains('água') || lower.contains('agua')) {
      return 'Contador de água';
    }
    if (lower.isEmpty || lower.contains('refei')) {
      return 'Café da manhã';
    }
    return 'Personalizar Refeições';
  }
}
