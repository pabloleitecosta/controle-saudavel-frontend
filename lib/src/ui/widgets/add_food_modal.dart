import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/nutrition_estimate.dart';
import '../../providers/auth_provider.dart';
import '../../services/image_recognition_service.dart';
import '../../services/user_service.dart';
import '../screens/recipe_create_screen.dart';
import '../screens/add_meal_manual_screen.dart';

class AddFoodModal extends StatefulWidget {
  final String mealType;
  final DateTime targetDate;
  const AddFoodModal({super.key, required this.mealType, required this.targetDate});

  @override
  State<AddFoodModal> createState() => _AddFoodModalState();
}

class _AddFoodModalState extends State<AddFoodModal> {
  final Color _softBlue = const Color(0xFFA8D0E6);
  final Color _darkText = const Color(0xFF0F172A);
  final ImagePicker _picker = ImagePicker();
  final ImageRecognitionService _imageService = ImageRecognitionService();
  final UserService _userService = UserService();

  XFile? _selectedImage;
  NutritionEstimate? _estimate;
  bool _loading = false;

  Future<void> _pickImage(ImageSource source) async {
    final image = await _picker.pickImage(source: source);
    if (image == null) return;

    setState(() {
      _selectedImage = image;
      _estimate = null;
      _loading = true;
    });

    try {
      final result = await _imageService.recognize(File(image.path));
      setState(() => _estimate = result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao reconhecer imagem: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _saveMeal() async {
    if (_estimate == null) return;
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    setState(() => _loading = true);

    try {
      await _userService.saveMealFromEstimate(
        userId: user.id,
        date: widget.targetDate,
        mealType: widget.mealType,
        estimate: _estimate!,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Refeicao adicionada com sucesso!')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar refeicao: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Camera'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galeria'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 50,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(50),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Adicionar alimento',
            style: TextStyle(
              color: _darkText,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            widget.mealType,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),
          _floatingMenu(),
          const SizedBox(height: 20),
          if (_selectedImage != null) _previewImage(),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          if (!_loading && _estimate != null) _editableNutritionList(),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _loading ? null : () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        _loading || _estimate == null ? null : _saveMeal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _softBlue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Salvar refeicao'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _floatingMenu() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 15,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _menuIcon(Icons.camera_alt_outlined, 'Foto', _showImageSourceSheet),
          _menuIcon(Icons.auto_awesome, 'Criar\nReceita', () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RecipeCreateScreen(),
              ),
            );
          }),
          _menuIcon(Icons.edit, 'Alimento\nmanual', () {
            Navigator.pop(context, {
              'manual': true,
              'mealType': widget.mealType,
              'targetDate': widget.targetDate.toIso8601String(),
            });
          }),
          _menuIcon(Icons.qr_code_scanner, 'Codigo', () {}),
        ],
      ),
    );
  }

  Widget _menuIcon(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: _softBlue.withOpacity(.2),
            child: Icon(icon, size: 28, color: _softBlue),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Widget _previewImage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.file(
          File(_selectedImage!.path),
          height: 140,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _editableNutritionList() {
    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _estimate!.items.length,
        itemBuilder: (_, index) {
          final item = _estimate!.items[index];
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _darkText,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "${item.calories.toStringAsFixed(0)} kcal - "
                    "P: ${item.protein.toStringAsFixed(1)}g  "
                    "C: ${item.carbs.toStringAsFixed(1)}g  "
                    "G: ${item.fat.toStringAsFixed(1)}g",
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Porcao (${item.servingUnit})",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _softBlue,
                    ),
                  ),
                  Slider(
                    value: item.multiplier.toDouble(),
                    min: 0.5,
                    max: 5,
                    divisions: 9,
                    label: "${item.multiplier}x",
                    activeColor: _softBlue,
                    onChanged: (value) {
                      setState(() {
                        item.multiplier =
                            double.parse(value.toStringAsFixed(1));
                        _estimate!.recalculateTotals();
                      });
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
