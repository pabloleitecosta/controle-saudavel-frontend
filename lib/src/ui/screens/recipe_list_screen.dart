import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/food_item.dart';
import '../../services/food_service.dart';
import '../../services/recipes_service.dart';
import 'recipe_create_screen.dart';

class RecipeListScreen extends StatefulWidget {
  static const route = "/recipes";

  final String? mealType;
  final DateTime? date;

  const RecipeListScreen({
    super.key,
    this.mealType,
    this.date,
  });

  @override
  State<RecipeListScreen> createState() => _RecipeListScreenState();
}

class _RecipeListScreenState extends State<RecipeListScreen>
    with SingleTickerProviderStateMixin {
  final softBlue = const Color(0xFFA8D0E6);
  final darkText = const Color(0xFF0F172A);

  late final TabController _tabController;
  final _recipesService = RecipesService();
  final _foodService = FoodService();

  List<Map<String, dynamic>> myRecipes = [];
  List<Map<String, dynamic>> exploreRecipes = [];
  List<FoodItem> foods = [];

  bool loadingRecipes = false;
  bool loadingFoods = false;

  final TextEditingController searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    setState(() => loadingRecipes = true);
    try {
      final mine = await _recipesService.listMyRecipes();
      final explore = await _recipesService.exploreRecipes();
      if (!mounted) return;
      setState(() {
        myRecipes = mine;
        exploreRecipes = explore;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao buscar receitas: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => loadingRecipes = false);
      }
    }
  }

  Future<void> _searchFoods(String term) async {
    if (term.isEmpty) {
      setState(() => foods = []);
      return;
    }

    setState(() => loadingFoods = true);
    try {
      final result = await _foodService.search(term);
      setState(() => foods = result);
    } finally {
      setState(() => loadingFoods = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = widget.date ?? DateTime.now();
    final dateStr = DateFormat("EEEE, d").format(selectedDate);
    final mealTitle = widget.mealType ?? 'Cafe da Manha';
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              mealTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              dateStr,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.green),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Container(
            color: Colors.black87,
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: 'LIVRO DE RECEITAS'),
                Tab(text: 'RECEITAS'),
                Tab(text: 'ALIMENTO'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyRecipesTab(),
          _buildExploreRecipesTab(),
          _buildFoodTab(),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _floatingBottomBar(),
    );
  }

  Widget _buildMyRecipesTab() {
    if (loadingRecipes) {
      return const Center(child: CircularProgressIndicator());
    }

    if (myRecipes.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Voce ainda nao tem receitas salvas.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: myRecipes.length,
      itemBuilder: (_, index) {
        final recipe = myRecipes[index];
        return _recipeCard(recipe);
      },
    );
  }

  Widget _buildExploreRecipesTab() {
    if (loadingRecipes && exploreRecipes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: exploreRecipes.length,
      itemBuilder: (_, index) => _recipeCard(exploreRecipes[index]),
    );
  }

  Widget _recipeCard(Map<String, dynamic> recipe) {
    final String? imageUrl = recipe['imageUrl'] as String?;
    return Container(
      height: 150,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.black12,
        image: imageUrl != null
            ? DecorationImage(
                image: NetworkImage(imageUrl),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: Stack(
        children: [
          if (imageUrl == null)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.grey.shade300,
                ),
              ),
            ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    recipe['name']?.toString() ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          blurRadius: 4,
                          color: Colors.black,
                        ),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${recipe['timeMinutes']} min',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: searchCtrl,
            onChanged: _searchFoods,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Pesquisar alimentos',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (loadingFoods) const LinearProgressIndicator(),
          Expanded(
            child: ListView.builder(
              itemCount: foods.length,
              itemBuilder: (_, index) {
                final item = foods[index];
                return ListTile(
                  title: Text(item.name),
                  subtitle: Text(
                    "${item.calories.toStringAsFixed(0)} kcal - P: ${item.protein.toStringAsFixed(1)}g C: ${item.carbs.toStringAsFixed(1)}g G: ${item.fat.toStringAsFixed(1)}g",
                  ),
                  onTap: () => Navigator.pop(context, item),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _floatingBottomBar() {
    return Container(
      height: 70,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _bottomIcon(Icons.camera_alt_outlined, () {}),
          _bottomIcon(Icons.auto_awesome, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RecipeCreateScreen()),
            );
          }),
          _bottomIcon(Icons.qr_code_scanner, () {}),
        ],
      ),
    );
  }

  Widget _bottomIcon(IconData icon, VoidCallback onTap) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.green, size: 26),
    );
  }
}
