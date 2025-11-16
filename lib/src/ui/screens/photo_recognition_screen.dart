import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/i18n.dart';
import '../../models/nutrition_estimate.dart';
import '../../providers/auth_provider.dart';
import '../../services/image_recognition_service.dart';
import '../../services/user_service.dart';

class PhotoRecognitionScreen extends StatefulWidget {
  static const route = '/meal/photo';
  const PhotoRecognitionScreen({super.key});

  @override
  State<PhotoRecognitionScreen> createState() =>
      _PhotoRecognitionScreenState();
}

class _PhotoRecognitionScreenState extends State<PhotoRecognitionScreen> {
  final _picker = ImagePicker();
  final _imageService = ImageRecognitionService();
  final _userService = UserService();

  File? _image;
  NutritionEstimate? _estimate;
  bool _loading = false;

  Future<void> _pickImage() async {
    final picked =
        await _picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (picked != null) {
      setState(() {
        _image = File(picked.path);
      });
      await _sendToApi();
    }
  }

  Future<void> _sendToApi() async {
    if (_image == null) return;
    setState(() {
      _loading = true;
    });
    try {
      final result = await _imageService.recognize(_image!);
      setState(() {
        _estimate = result;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao reconhecer imagem: $e')),
      );
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _saveMeal() async {
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user == null || _estimate == null) return;

    try {
      await _userService.saveMeal(
        userId: user.id,
        date: DateTime.now(),
        items: _estimate!.items
            .map((i) => {
                  'label': i.label,
                  'calories': i.calories,
                  'protein': i.protein,
                  'carbs': i.carbs,
                  'fat': i.fat,
                })
            .toList(),
        totalCalories: _estimate!.totalCalories,
        totalProtein: _estimate!.totalProtein,
        totalCarbs: _estimate!.totalCarbs,
        totalFat: _estimate!.totalFat,
        source: 'photo',
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
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
        title: Text(t.t('add_meal_photo')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_image != null)
              Image.file(
                _image!,
                height: 200,
              ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loading ? null : _pickImage,
              icon: const Icon(Icons.camera_alt),
              label: Text(t.t('add_meal_photo')),
            ),
            const SizedBox(height: 16),
            if (_loading) const CircularProgressIndicator(),
            if (_estimate != null && !_loading)
              Expanded(
                child: Column(
                  children: [
                    Text(
                        'Calorias: ${_estimate!.totalCalories.toStringAsFixed(0)}'),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView(
                        children: _estimate!.items
                            .map((item) => ListTile(
                                  title: Text(item.label),
                                  subtitle: Text(
                                      '${item.calories.toStringAsFixed(0)} kcal - P ${item.protein.toStringAsFixed(1)}g / C ${item.carbs.toStringAsFixed(1)}g / G ${item.fat.toStringAsFixed(1)}g'),
                                ))
                            .toList(),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _saveMeal,
                      child: const Text('Salvar refeição'),
                    )
                  ],
                ),
              )
          ],
        ),
      ),
    );
  }
}
