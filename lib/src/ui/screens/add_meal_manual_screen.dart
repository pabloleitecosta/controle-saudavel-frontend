import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/i18n.dart';
import '../../models/food_item.dart';
import '../../models/meal_log.dart';
import '../../providers/auth_provider.dart';
import '../../services/custom_food_service.dart';
import '../../services/food_service.dart';
import '../../services/user_service.dart';
import '../../services/recipes_service.dart';
import '../widgets/add_custom_food_sheet.dart';
import 'recipe_create_screen.dart';

class AddMealManualScreen extends StatefulWidget {
  static const route = '/meal/add/manual';
  final String mealType;
  const AddMealManualScreen({super.key, required this.mealType});

  @override
  State<AddMealManualScreen> createState() => _AddMealManualScreenState();
}

class _AddMealManualScreenState extends State<AddMealManualScreen>
    with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  final _foodService = FoodService();
  final _userService = UserService();
  final _customService = CustomFoodService();
  final _recipesService = RecipesService();
  late final TabController _tabController;

  List<FoodItem> _results = [];
  List<Map<String, dynamic>> _customFoods = [];
  List<Map<String, dynamic>> _recipes = [];
  List<MealLog> _recentMeals = [];
  final List<Map<String, dynamic>> _selectedItems = [];
  bool _loadingSearch = false;
  bool _loadingCustom = false;
  bool _loadingRecipes = false;
  bool _loadingRecent = false;
  String _recipeQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCustomFoods();
    _loadRecipes();
    _loadRecentMeals();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCustomFoods() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    setState(() => _loadingCustom = true);
    try {
      final items = await _customService.list(user.id);
      setState(() => _customFoods = items);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar alimentos salvos: $e')),
      );
    } finally {
      setState(() => _loadingCustom = false);
    }
  }

  Future<void> _loadRecipes() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    setState(() => _loadingRecipes = true);
    try {
      final data = await _recipesService.exploreRecipes(user.id);
      setState(() => _recipes = data);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar receitas: $e')),
      );
    } finally {
      if (mounted) setState(() => _loadingRecipes = false);
    }
  }

  Future<void> _loadRecentMeals() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    setState(() => _loadingRecent = true);
    try {
      final meals = await _userService.fetchMeals(user.id);
      setState(() => _recentMeals = meals.take(5).toList());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar recentes: $e')),
      );
    } finally {
      if (mounted) setState(() => _loadingRecent = false);
    }
  }

  Future<void> _search() async {
    setState(() => _loadingSearch = true);
    try {
      final foods = await _foodService.search(_searchCtrl.text.trim());
      setState(() => _results = foods);
    } finally {
      setState(() => _loadingSearch = false);
    }
  }

  Future<void> _addFoodEntry({
    required String label,
    required double calories,
    required double protein,
    required double carbs,
    required double fat,
    double baseServing = 100,
    String baseUnit = 'g',
  }) async {
    double quantity = 1;
    await showModalBottomSheet(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text(
                    'Porção: ${(quantity * baseServing).toStringAsFixed(0)} $baseUnit'),
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
                    setState(() {
                      _selectedItems.add({
                        'label': label,
                        'calories': calories * quantity,
                        'protein': protein * quantity,
                        'carbs': carbs * quantity,
                        'fat': fat * quantity,
                      });
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Adicionar'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _addFood(FoodItem food) {
    _addFoodEntry(
      label: food.name,
      calories: food.calories,
      protein: food.protein,
      carbs: food.carbs,
      fat: food.fat,
      baseServing: food.servingSize,
      baseUnit: food.servingUnit,
    );
  }

  void _addCustomFood(Map<String, dynamic> food) {
    _addFoodEntry(
      label: food['name']?.toString() ?? food['label']?.toString() ?? '',
      calories: (food['calories'] ?? 0).toDouble(),
      protein: (food['protein'] ?? 0).toDouble(),
      carbs: (food['carbs'] ?? 0).toDouble(),
      fat: (food['fat'] ?? 0).toDouble(),
      baseServing: (food['portionValue'] ?? food['serving'] ?? 100).toDouble(),
      baseUnit: food['portionUnit']?.toString() ??
          food['servingUnit']?.toString() ??
          'g',
    );
  }

  Future<void> _saveMeal() async {
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user == null || _selectedItems.isEmpty) return;

    final hadMeals = await _userService.hasAnyMeal(user.id);

    final totalCalories =
        _selectedItems.fold<double>(0, (v, i) => v + (i['calories'] as double));
    final totalProtein =
        _selectedItems.fold<double>(0, (v, i) => v + (i['protein'] as double));
    final totalCarbs =
        _selectedItems.fold<double>(0, (v, i) => v + (i['carbs'] as double));
    final totalFat =
        _selectedItems.fold<double>(0, (v, i) => v + (i['fat'] as double));

    try {
      await _userService.saveMeal(
        userId: user.id,
        date: DateTime.now(),
        items: _selectedItems,
        totalCalories: totalCalories,
        totalProtein: totalProtein,
        totalCarbs: totalCarbs,
        totalFat: totalFat,
        mealType: widget.mealType,
        source: 'manual',
      );
      if (!hadMeals && mounted) {
        await _showFirstBiteDialog();
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar refeição: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.t('add_meal_manual')),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Tipo de refeição: ${widget.mealType}',
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          _buildTabHeader(),
          const SizedBox(height: 8),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRecipesTab(),
                _buildFoodTab(),
                _buildRecentTab(),
              ],
            ),
          ),
          if (_selectedItems.isNotEmpty) _buildSelectionBar(),
        ],
      ),
    );
  }

  Widget _buildTabHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(30),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey.shade600,
        indicator: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(30),
        ),
        tabs: const [
          Tab(text: 'Receitas'),
          Tab(text: 'Alimento'),
          Tab(text: 'Recentes'),
        ],
      ),
    );
  }

  Widget _buildRecipesTab() {
    final filtered = _recipes
        .where(
          (recipe) =>
              recipe['name']
                  ?.toString()
                  .toLowerCase()
                  .contains(_recipeQuery.toLowerCase()) ??
              false,
        )
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(
              labelText: 'Pesquisar Receitas',
              suffixIcon: Icon(Icons.search),
            ),
            onChanged: (value) => setState(() => _recipeQuery = value),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () async {
                final created = await Navigator.pushNamed(
                  context,
                  RecipeCreateScreen.route,
                );
                if (created == true) {
                  _loadRecipes();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Adicionar nova receita'),
            ),
          ),
          if (_loadingRecipes) const LinearProgressIndicator(),
          const SizedBox(height: 8),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      _loadingRecipes
                          ? 'Carregando receitas...'
                          : 'Nenhuma receita encontrada.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  )
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (_, index) {
                      final recipe = filtered[index];
                      return _RecipeCard(
                        recipe: recipe,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Integração com diário em breve!'),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTab() {
    if (_loadingRecent) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_recentMeals.isEmpty) {
      return Center(
        child: Text(
          'Você ainda não registrou refeições recentes.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemBuilder: (_, index) {
        final meal = _recentMeals[index];
        return ListTile(
          leading: const Icon(Icons.history),
          title: Text(meal.date),
          subtitle: Text(
              '${meal.totalCalories.toStringAsFixed(0)} kcal · ${meal.items.length} itens'),
        );
      },
      separatorBuilder: (_, __) => const Divider(),
      itemCount: _recentMeals.length,
    );
  }

  Widget _buildFoodTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          TextField(
            controller: _searchCtrl,
            onSubmitted: (_) => _search(),
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
                if (_results.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Resultados',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ..._results.map(
                  (f) => ListTile(
                    title: Text(f.name),
                    subtitle: Text(
                      '${f.calories.toStringAsFixed(0)} kcal / ${f.servingSize}${f.servingUnit}',
                    ),
                    onTap: () => _addFood(f),
                  ),
                ),
                const Divider(),
                if (_loadingCustom)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_customFoods.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      'Seus alimentos',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                  ..._customFoods.map(
                    (f) => ListTile(
                      title: Text(f['name']?.toString() ?? ''),
                      subtitle: Text(
                        '${(f['calories'] ?? 0)} kcal / ${(f['portionValue'] ?? 0)} ${f['portionUnit'] ?? 'g'}',
                      ),
                      onTap: () => _addCustomFood(f),
                    ),
                  ),
                  const Divider(),
                ],
                ListTile(
                  leading: const Icon(Icons.restaurant_menu),
                  title: const Text('Adicionar novo alimento'),
                  subtitle: const Text(
                    'Cadastre valores nutricionais manualmente',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final custom =
                        await showModalBottomSheet<Map<String, dynamic>>(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      builder: (_) => const AddCustomFoodSheet(),
                    );
                    if (custom != null) {
                      final user = context.read<AuthProvider>().user;
                      if (user == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Entre para salvar o alimento novo.'),
                          ),
                        );
                      } else {
                        try {
                          final saved =
                              await _customService.create(user.id, custom);
                          setState(() {
                            _customFoods.insert(0, saved);
                          });
                          _addCustomFood(saved);
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Erro ao salvar alimento: $e')),
                          );
                        }
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          border: Border(
            top: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_selectedItems.length} itens selecionados',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextButton(
                    onPressed: _showSelectedItems,
                    child: const Text('Ver detalhes'),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 180,
              height: 44,
              child: ElevatedButton(
                onPressed: _saveMeal,
                child: const Text('Salvar refeição'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSelectedItems() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Itens selecionados',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 12),
            ..._selectedItems.map(
              (i) => ListTile(
                title: Text(i['label'].toString()),
                subtitle: Text(
                  '${(i['calories'] as double).toStringAsFixed(0)} kcal',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showFirstBiteDialog() {
    return showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Primeira Mordida'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.emoji_food_beverage, size: 56, color: Colors.green),
            SizedBox(height: 12),
            Text(
              'Parabéns por registrar seu primeiro alimento! Continue registrando para desbloquear novas medalhas.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Ver medalhas'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  final Map<String, dynamic> recipe;
  final VoidCallback onTap;

  const _RecipeCard({
    required this.recipe,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        onTap: onTap,
        leading: recipe['imageUrl'] != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  recipe['imageUrl'],
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                ),
              )
            : const Icon(Icons.menu_book),
        title: Text(recipe['name']?.toString() ?? ''),
        subtitle: Text(
          recipe['description']?.toString() ?? '',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.timer, size: 16),
            Text(
              '${recipe['timeMinutes'] ?? 0} min',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
