import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import 'profile_goals_screen.dart';
import 'add_meal_screen.dart';
import '../widgets/add_food_modal.dart';

class HomeScreen extends StatefulWidget {
  static const route = "/home";
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final softBlue = const Color(0xFFA8D0E6);
  final darkText = const Color(0xFF0F172A);

  int selectedDay = DateTime.now().weekday % 7;
  List<String> week = ["S", "T", "Q", "Q", "S", "S", "D"];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final AppUser? user = auth.user;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(user),
              const SizedBox(height: 8),
              _buildWeeklyStreak(),
              const SizedBox(height: 10),
              _buildPlanCards(),
              const SizedBox(height: 20),
              _buildMacroBar(),
              const SizedBox(height: 20),
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
    );
  }

  // ------------------------------------------------------------------
  // HEADER
  // ------------------------------------------------------------------
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

  // ------------------------------------------------------------------
  // WEEKLY STREAK
  // ------------------------------------------------------------------
  Widget _buildWeeklyStreak() {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        itemBuilder: (_, i) {
          bool active = i == selectedDay;
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
                  week[i],
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

  // ------------------------------------------------------------------
  // PLAN CARDS
  // ------------------------------------------------------------------
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
          style: TextStyle(
            color: Color(0xFF1B1B1B),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // MACRO BAR
  // ------------------------------------------------------------------
  Widget _buildMacroBar() {
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
            _macro("Gord", "-"),
            _macro("Carb", "-"),
            _macro("Prot", "-"),
            _macro("IDR", "-"),
            _macro("Cal", "0"),
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

  // ------------------------------------------------------------------
  // MEALS SECTION
  // ------------------------------------------------------------------
  Widget _buildMealsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _mealCard("Cafe da Manha", Icons.sunny, context),
          _mealCard("Almoco", Icons.lunch_dining, context),
          _mealCard("Jantar", Icons.nightlight_round, context),
          _mealCard("Lanches/Outros", Icons.bedtime, context),
        ],
      ),
    );
  }

Widget _mealCard(String title, IconData icon, BuildContext context) {
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
    child: Row(
      children: [
        Icon(icon, color: softBlue, size: 30),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: darkText,
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            _openAddFoodModal(context, title);
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: softBlue,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ],
    ),
  );
}

void _openAddFoodModal(BuildContext context, String mealType) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return AddFoodModal(mealType: mealType);
    },
  );
}

  // ------------------------------------------------------------------
  // PREMIUM OPTIONS
  // ------------------------------------------------------------------
  Widget _buildPremiumOptions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _optionCard("Minhas Metas de Saude",
              "TMB, TDEE e metas nutricionais", Icons.favorite_border, () {
            Navigator.pushNamed(context, ProfileGoalsScreen.route);
          }),
          _optionCard("Contador de Agua", "Hidratacao diaria",
              Icons.water_drop_outlined, () {}),
          _optionCard("Exercicio e Sono", "Registre sua rotina",
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
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: darkText)),
        subtitle: Text(sub,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
        trailing: Icon(Icons.chevron_right, color: Colors.grey.shade500),
      ),
    );
  }

  // ------------------------------------------------------------------
  // DAILY SUMMARY
  // ------------------------------------------------------------------
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
            Text("Resumo diario",
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
}
