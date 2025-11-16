import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/i18n.dart';
import '../../models/food_item.dart';
import '../../providers/auth_provider.dart';
import '../../services/food_service.dart';
import '../../services/user_service.dart';

class AddMealManualScreen extends StatefulWidget {
  static const route = '/meal/add/manual';
  const AddMealManualScreen({super.key});

  @override
  State<AddMealManualScreen> createState() => _AddMealManualScreenState();
}

class _AddMealManualScreenState extends State<AddMealManualScreen> {
  final _searchCtrl = TextEditingController();
  final _foodService = FoodService();
  final _userService = UserService();

  List<FoodItem> _results = [];
  final List<Map<String, dynamic>> _selectedItems = [];
  bool _loadingSearch = false;

  Future<void> _search() async {
    setState(() => _loadingSearch = true);
    try {
      final foods = await _foodService.search(_searchCtrl.text.trim());
      setState(() => _results = foods);
    } finally {
      setState(() => _loadingSearch = false);
    }
  }

  void _addFood(FoodItem food) async {
    double quantity = 1;
    await showModalBottomSheet(
      context: context,
      builder: (_) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(food.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Text('Porções: ${quantity.toStringAsFixed(1)}'),
                Slider(
                  min: 0.5,
                  max: 3,
                  divisions: 5,
                  value: quantity,
                  label: quantity.toStringAsFixed(1),
                  onChanged: (v) => setModalState(() => quantity = v),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    _selectedItems.add({
                      'label': food.name,
                      'calories': food.calories * quantity,
                      'protein': food.protein * quantity,
                      'carbs': food.carbs * quantity,
                      'fat': food.fat * quantity,
                    });
                    Navigator.pop(context);
                    setState(() {});
                  },
                  child: const Text('Adicionar'),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  Future<void> _saveMeal() async {
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user == null || _selectedItems.isEmpty) return;

    final totalCalories = _selectedItems.fold<double>(0, (v, i) => v + (i['calories'] as double));
    final totalProtein = _selectedItems.fold<double>(0, (v, i) => v + (i['protein'] as double));
    final totalCarbs = _selectedItems.fold<double>(0, (v, i) => v + (i['carbs'] as double));
    final totalFat = _selectedItems.fold<double>(0, (v, i) => v + (i['fat'] as double));

    try {
      await _userService.saveMeal(
        userId: user.id,
        date: DateTime.now(),
        items: _selectedItems,
        totalCalories: totalCalories,
        totalProtein: totalProtein,
        totalCarbs: totalCarbs,
        totalFat: totalFat,
        source: 'manual',
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar refei��ǜo: $e')),
      );
    }

  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.t('add_meal_manual')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                labelText: 'Buscar alimento',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _search,
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_loadingSearch) const LinearProgressIndicator(),
            Expanded(
              child: ListView(
                children: [
                  ..._results.map((f) => ListTile(
                        title: Text(f.name),
                        subtitle: Text('${f.calories.toStringAsFixed(0)} kcal / ${f.servingSize}${f.servingUnit}'),
                        onTap: () => _addFood(f),
                      )),
                  if (_selectedItems.isNotEmpty) const Divider(),
                  if (_selectedItems.isNotEmpty)
                    ..._selectedItems.map((i) => ListTile(
                          title: Text(i['label'].toString()),
                          subtitle: Text(
                              '${(i['calories'] as double).toStringAsFixed(0)} kcal'),
                        )),
                ],
              ),
            ),
            if (_selectedItems.isNotEmpty)
              ElevatedButton(
                onPressed: _saveMeal,
                child: const Text('Salvar refeição'),
              ),
          ],
        ),
      ),
    );
  }
}
