import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/recipes_service.dart';

class RecipeCreateScreen extends StatefulWidget {
  static const route = "/recipes/new";

  const RecipeCreateScreen({super.key});

  @override
  State<RecipeCreateScreen> createState() => _RecipeCreateScreenState();
}

class _RecipeCreateScreenState extends State<RecipeCreateScreen> {
  final softBlue = const Color(0xFFA8D0E6);
  final darkText = const Color(0xFF0F172A);

  final _formKeyStep1 = GlobalKey<FormState>();
  final _formKeyStep2 = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _ingredientsCtrl = TextEditingController();
  final _stepsCtrl = TextEditingController();
  final _timeCtrl = TextEditingController();

  int step = 0;
  bool saving = false;

  final _recipesService = RecipesService();

  void _next() {
    if (step == 0 && _formKeyStep1.currentState?.validate() != true) return;
    if (step == 1 && _formKeyStep2.currentState?.validate() != true) return;
    setState(() => step++);
  }

  Future<void> _save() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entre para criar receitas.')),
      );
      return;
    }

    setState(() => saving = true);

    await _recipesService.createRecipe(user.id, {
      "name": _nameCtrl.text,
      "description": _descCtrl.text,
      "ingredients": _ingredientsCtrl.text,
      "steps": _stepsCtrl.text,
      "timeMinutes": int.tryParse(_timeCtrl.text) ?? 0,
    });

    setState(() => saving = false);
    Navigator.pop(context, true);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _ingredientsCtrl.dispose();
    _stepsCtrl.dispose();
    _timeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stepsTitles = [
      "1º Passo. Informações da receita",
      "2º Passo. Ingredientes",
      "3º Passo. Modo de preparo",
      "4º Passo. Revisar & salvar",
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: .5,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Nova Receita",
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (step < 3)
            TextButton(
              onPressed: _next,
              child: const Text("Próximo Passo"),
            )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              stepsTitles[step],
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(child: _buildStepContent()),
            if (step == 3)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: softBlue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: saving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Salvar Receita",
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (step) {
      case 0:
        return Form(
          key: _formKeyStep1,
          child: Column(
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: "Nome da receita *",
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? "Informe o nome" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "Descrição *",
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? "Informe a descrição" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _timeCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Tempo de preparo (min)",
                ),
              ),
            ],
          ),
        );
      case 1:
        return Form(
          key: _formKeyStep2,
          child: TextFormField(
            controller: _ingredientsCtrl,
            maxLines: 8,
            decoration: const InputDecoration(
              alignLabelWithHint: true,
              labelText: "Ingredientes (1 por linha) *",
            ),
            validator: (v) =>
                (v == null || v.isEmpty) ? "Informe os ingredientes" : null,
          ),
        );
      case 2:
        return TextField(
          controller: _stepsCtrl,
          maxLines: 10,
          decoration: const InputDecoration(
            alignLabelWithHint: true,
            labelText: "Modo de preparo (passo a passo)",
          ),
        );
      case 3:
      default:
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Nome: ${_nameCtrl.text}"),
              const SizedBox(height: 8),
              Text("Descrição: ${_descCtrl.text}"),
              const SizedBox(height: 8),
              Text("Tempo: ${_timeCtrl.text} min"),
              const SizedBox(height: 16),
              const Text("Ingredientes:"),
              Text(_ingredientsCtrl.text),
              const SizedBox(height: 16),
              const Text("Modo de preparo:"),
              Text(_stepsCtrl.text),
            ],
          ),
        );
    }
  }
}
