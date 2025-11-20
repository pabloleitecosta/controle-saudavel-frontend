import 'package:flutter/material.dart';
import '../../core/theme.dart';

class AddCustomFoodSheet extends StatefulWidget {
  const AddCustomFoodSheet({super.key});

  @override
  State<AddCustomFoodSheet> createState() => _AddCustomFoodSheetState();
}

class _AddCustomFoodSheetState extends State<AddCustomFoodSheet> {
  final _nameCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _servingCtrl = TextEditingController(text: '100');
  final _unitCtrl = TextEditingController(text: 'g');
  final _caloriesCtrl = TextEditingController(text: '0');
  final _proteinCtrl = TextEditingController(text: '0');
  final _carbsCtrl = TextEditingController(text: '0');
  final _fatCtrl = TextEditingController(text: '0');

  int _step = 0;
  double _multiplier = 1;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descriptionCtrl.dispose();
    _servingCtrl.dispose();
    _unitCtrl.dispose();
    _caloriesCtrl.dispose();
    _proteinCtrl.dispose();
    _carbsCtrl.dispose();
    _fatCtrl.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_step == 0 && _nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o nome do alimento')),
      );
      return;
    }
    if (_step == 1) {
      final fields = [
        _servingCtrl,
        _caloriesCtrl,
        _proteinCtrl,
        _carbsCtrl,
        _fatCtrl,
      ];
      for (final ctrl in fields) {
        if (double.tryParse(ctrl.text.replaceAll(',', '.')) == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Preencha os valores nutricionais')),
          );
          return;
        }
      }
    }
    if (_step < 2) {
      setState(() => _step++);
    } else {
      _finish();
    }
  }

  void _finish() {
    final serving = double.parse(_servingCtrl.text.replaceAll(',', '.'));
    final calories = double.parse(_caloriesCtrl.text.replaceAll(',', '.'));
    final protein = double.parse(_proteinCtrl.text.replaceAll(',', '.'));
    final carbs = double.parse(_carbsCtrl.text.replaceAll(',', '.'));
    final fat = double.parse(_fatCtrl.text.replaceAll(',', '.'));

    Navigator.pop(context, {
      'name': _nameCtrl.text.trim(),
      'description': _descriptionCtrl.text.trim(),
      'portionValue': serving * _multiplier,
      'portionUnit': _unitCtrl.text.trim(),
      'calories': calories * _multiplier,
      'protein': protein * _multiplier,
      'carbs': carbs * _multiplier,
      'fat': fat * _multiplier,
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _stepTitle(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_step == 0) _buildInfoStep(),
                if (_step == 1) _buildNutritionStep(),
                if (_step == 2) _buildConfirmStep(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (_step > 0)
                      TextButton(
                        onPressed: () => setState(() => _step--),
                        child: const Text('Voltar'),
                      )
                    else
                      const SizedBox(width: 8),
                    const Spacer(),
                    SizedBox(
                      width: 180,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: _nextStep,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(_step == 2 ? 'Salvar' : 'Próximo passo'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _stepTitle() {
    switch (_step) {
      case 0:
        return '1º Passo. Informações básicas';
      case 1:
        return '2º Passo. Valor nutricional';
      case 2:
        return 'Revise e salve';
      default:
        return '';
    }
  }

  Widget _buildInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Nome do alimento *'),
        TextField(
          controller: _nameCtrl,
          decoration: const InputDecoration(
            hintText: 'Insira o nome',
          ),
        ),
        const SizedBox(height: 16),
        const Text('Descrição'),
        TextField(
          controller: _descriptionCtrl,
          decoration: const InputDecoration(
            hintText: 'Descrição breve',
          ),
        ),
      ],
    );
  }

  Widget _buildNutritionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _servingCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Quantidade'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _unitCtrl,
                decoration: const InputDecoration(labelText: 'Unidade'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _numericField(_caloriesCtrl, 'Calorias'),
        _numericField(_proteinCtrl, 'Proteínas (g)'),
        _numericField(_carbsCtrl, 'Carboidratos (g)'),
        _numericField(_fatCtrl, 'Gorduras (g)'),
      ],
    );
  }

  Widget _numericField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  Widget _buildConfirmStep() {
    final serving = double.tryParse(_servingCtrl.text.replaceAll(',', '.')) ?? 0;
    final unit = _unitCtrl.text.trim();
    final calories = double.tryParse(_caloriesCtrl.text.replaceAll(',', '.')) ?? 0;
    final protein = double.tryParse(_proteinCtrl.text.replaceAll(',', '.')) ?? 0;
    final carbs = double.tryParse(_carbsCtrl.text.replaceAll(',', '.')) ?? 0;
    final fat = double.tryParse(_fatCtrl.text.replaceAll(',', '.')) ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _nameCtrl.text,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        if (_descriptionCtrl.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _descriptionCtrl.text,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        const SizedBox(height: 12),
        Text('Porção (${serving.toStringAsFixed(0)} $unit)'),
        Slider(
          min: 0.25,
          max: 3,
          divisions: 11,
          value: _multiplier,
          label: '${(_multiplier * serving).toStringAsFixed(0)} $unit',
          onChanged: (v) => setState(() => _multiplier = v),
        ),
        const SizedBox(height: 8),
        _macroRow('Calorias', (calories * _multiplier).toStringAsFixed(0)),
        _macroRow('Proteínas', '${(protein * _multiplier).toStringAsFixed(1)} g'),
        _macroRow('Carboidratos', '${(carbs * _multiplier).toStringAsFixed(1)} g'),
        _macroRow('Gorduras', '${(fat * _multiplier).toStringAsFixed(1)} g'),
      ],
    );
  }

  Widget _macroRow(String label, String value) {
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
