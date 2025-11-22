import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/meal_log.dart';
import '../../providers/auth_provider.dart';
import '../../services/user_service.dart';

class MealDetailScreen extends StatelessWidget {
  final MealLog meal;
  final MealLogItem item;
  final UserService _userService = UserService();

  MealDetailScreen({super.key, required this.meal, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, false),
        ),
        title: Text(item.label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              meal.mealType,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            _macroRow(),
            const SizedBox(height: 20),
            const Text(
              'Informação Nutricional',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _infoLine('Calorias', '${item.calories.toStringAsFixed(0)} kcal'),
            _infoLine('Proteínas', '${item.protein.toStringAsFixed(2)} g'),
            _infoLine('Carboidratos', '${item.carbs.toStringAsFixed(2)} g'),
            _infoLine('Gorduras', '${item.fat.toStringAsFixed(2)} g'),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _deleteMeal(context),
                    child: const Text('Apagar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Salvar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _macroRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _macroBox('Calorias', item.calories.toStringAsFixed(0)),
        _macroBox('Gorduras', item.fat.toStringAsFixed(2)),
        _macroBox('Carb', item.carbs.toStringAsFixed(2)),
        _macroBox('Proteínas', item.protein.toStringAsFixed(2)),
      ],
    );
  }

  Widget _macroBox(String label, String value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _infoLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Future<void> _deleteMeal(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir alimento'),
        content: const Text('Deseja excluir este alimento da refeição?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Excluir')),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _userService.deleteMeal(user.id, meal.id);
      if (context.mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir: $e')),
      );
    }
  }
}
