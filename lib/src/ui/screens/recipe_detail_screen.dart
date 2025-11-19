import 'package:flutter/material.dart';
import '../../models/nutrition_estimate.dart';
import '../../services/recipes_service.dart';

class RecipeDetailScreen extends StatefulWidget {
  static const route = "/recipes/detail";

  final String recipeId;

  const RecipeDetailScreen({super.key, required this.recipeId});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  final softBlue = const Color(0xFFA8D0E6);
  final darkText = const Color(0xFF0F172A);

  final _recipesService = RecipesService();

  Map<String, dynamic>? _recipe;
  NutritionEstimate? _nutrition;
  bool _loading = true;
  bool _loadingIa = false;

  @override
  void initState() {
    super.initState();
    _loadRecipe();
  }

  Future<void> _loadRecipe() async {
    setState(() => _loading = true);
    final r = await _recipesService.getRecipe(widget.recipeId);

    NutritionEstimate? n;
    if (r['nutrition'] != null) {
      n = NutritionEstimate.fromJson(r['nutrition']);
    }

    setState(() {
      _recipe = r;
      _nutrition = n;
      _loading = false;
    });
  }

  Future<void> _generateNutritionWithIA() async {
    setState(() => _loadingIa = true);
    final n = await _recipesService.refreshNutrition(widget.recipeId);
    setState(() {
      _nutrition = n;
      _loadingIa = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _recipe == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final r = _recipe!;
    final ingredients = (r['ingredients'] as List?)?.cast<String>() ?? [];
    final steps = (r['steps'] ?? '') as String;

    return Scaffold(
      appBar: AppBar(
        title: Text(r['name'] ?? 'Receita'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (r['imageUrl'] != null)
              Image.network(
                r['imageUrl'],
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r['name'] ?? '',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: darkText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (r['description'] != null)
                    Text(
                      r['description'],
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  const SizedBox(height: 12),
                  if (r['timeMinutes'] != null)
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 18),
                        const SizedBox(width: 4),
                        Text("${r['timeMinutes']} min"),
                      ],
                    ),
                  const SizedBox(height: 20),

                  Text(
                    "Ingredientes",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: darkText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...ingredients.map((ing) => Text("• $ing")),

                  const SizedBox(height: 20),
                  Text(
                    "Modo de preparo",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: darkText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(steps),

                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Informação Nutricional (IA)",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: darkText,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _loadingIa ? null : _generateNutritionWithIA,
                        icon: _loadingIa
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.auto_awesome),
                        label: const Text("Recalcular IA"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (_nutrition == null)
                    Text(
                      "Ainda não há tabela nutricional calculada.\nToque em \"Recalcular IA\" para gerar.",
                      style: TextStyle(color: Colors.grey.shade600),
                    ),

                  if (_nutrition != null) _buildNutritionTable(_nutrition!),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionTable(NutritionEstimate n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Totais (estimativa IA para a receita inteira):",
          style: TextStyle(color: Colors.grey.shade700),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _nutRow("Calorias", "${n.totalCalories.toStringAsFixed(0)} kcal"),
              _nutRow("Proteínas", "${n.totalProtein.toStringAsFixed(1)} g"),
              _nutRow("Carboidratos", "${n.totalCarbs.toStringAsFixed(1)} g"),
              _nutRow("Gorduras", "${n.totalFat.toStringAsFixed(1)} g"),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          "Itens detectados:",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: darkText,
          ),
        ),
        const SizedBox(height: 6),
        ...n.items.map((it) {
          return ListTile(
            dense: true,
            title: Text(it.label),
            subtitle: Text(
              "${it.adjustedServing.toStringAsFixed(0)} ${it.servingUnit} • "
              "${it.totalCalories.toStringAsFixed(0)} kcal",
            ),
            trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("P: ${it.totalProtein.toStringAsFixed(1)}g"),
                Text("C: ${it.totalCarbs.toStringAsFixed(1)}g"),
                Text("G: ${it.totalFat.toStringAsFixed(1)}g"),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _nutRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
