import 'package:flutter/material.dart';

class NutritionCard extends StatelessWidget {
  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  const NutritionCard({
    super.key,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildItem('kcal', calories.toStringAsFixed(0)),
            _buildItem('P', '${protein.toStringAsFixed(1)} g'),
            _buildItem('C', '${carbs.toStringAsFixed(1)} g'),
            _buildItem('G', '${fat.toStringAsFixed(1)} g'),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label),
      ],
    );
  }
}
