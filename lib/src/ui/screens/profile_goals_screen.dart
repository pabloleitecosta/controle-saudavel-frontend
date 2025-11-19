import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/weight_entry.dart';
import '../../providers/auth_provider.dart';
import '../../services/user_service.dart';

class ProfileGoalsScreen extends StatefulWidget {
  static const route = "/profile/goals";
  const ProfileGoalsScreen({super.key});

  @override
  State<ProfileGoalsScreen> createState() => _ProfileGoalsScreenState();
}

class _ProfileGoalsScreenState extends State<ProfileGoalsScreen> {
  final ageCtrl = TextEditingController();
  final weightCtrl = TextEditingController();
  final heightCtrl = TextEditingController();
  final TextEditingController _logWeightCtrl = TextEditingController();
  final UserService _userService = UserService();

  String sex = 'masculino';
  String goal = 'manter';
  double activityLevel = 1.2;
  double? tmb;
  double? tdee;

  bool loading = false;
  bool _fetchingProfile = false;
  Map<String, dynamic>? _profile;
  bool _loadingWeights = false;
  bool _savingWeight = false;
  DateTime _weightDate = DateTime.now();
  List<WeightEntry> _weightEntries = [];

  @override
  void initState() {
    super.initState();
    _loadExistingData();
    _loadWeightHistory();
  }

  @override
  void dispose() {
    ageCtrl.dispose();
    weightCtrl.dispose();
    heightCtrl.dispose();
    _logWeightCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadExistingData() async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;

    setState(() => _fetchingProfile = true);
    try {
      final data = await _userService.getUserProfile(userId);
      if (!mounted) return;

      if (data == null) {
        setState(() {
          _profile = null;
          _fetchingProfile = false;
        });
        return;
      }

      setState(() {
        _profile = data;
        ageCtrl.text = (data['age'] ?? '').toString();
        weightCtrl.text = (data['weight'] ?? '').toString();
        heightCtrl.text = (data['height'] ?? '').toString();
        sex = (data['sex'] as String?) ?? 'masculino';
        goal = (data['goal'] as String?) ?? 'manter';
        activityLevel = (data['activityLevel'] as num?)?.toDouble() ?? 1.2;
        tmb = (data['tmb'] as num?)?.toDouble();
        tdee = (data['tdee'] as num?)?.toDouble();
        _fetchingProfile = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _fetchingProfile = false);
      }
    }
  }

  Future<void> _loadWeightHistory() async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;
    setState(() => _loadingWeights = true);
    try {
      final history = await _userService.fetchWeightHistory(userId, limit: 30);
      if (!mounted) return;
      setState(() {
        _weightEntries = history;
        _loadingWeights = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _loadingWeights = false);
      }
    }
  }

  Future<void> _save() async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;

    setState(() => loading = true);
    try {
      await _userService.updateUserGoals(
        userId: userId,
        age: int.tryParse(ageCtrl.text),
        height: double.tryParse(heightCtrl.text),
        weight: double.tryParse(weightCtrl.text),
        sex: sex,
        goal: goal,
        activityLevel: activityLevel,
      );

      await _loadExistingData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Metas atualizadas com sucesso!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar metas: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> _saveWeightEntry() async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;

    final weightValue = double.tryParse(_logWeightCtrl.text.replaceAll(',', '.'));
    if (weightValue == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe um peso valido.')),
      );
      return;
    }

    setState(() => _savingWeight = true);
    try {
      await _userService.addWeightEntry(
        userId: userId,
        weight: weightValue,
        date: _weightDate,
      );
      _logWeightCtrl.clear();
      await _loadWeightHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Peso registrado com sucesso!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao registrar peso: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _savingWeight = false);
      }
    }
  }

  Future<void> _pickWeightDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _weightDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _weightDate = picked);
    }
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildSelectableChip(
    String label,
    bool selected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFA8D0E6) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            color: selected ? Colors.white : Colors.grey.shade700,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final userName =
        _profile?['name']?.toString() ?? auth.user?.name ?? 'Usuario';
    final userEmail =
        _profile?['email']?.toString() ?? auth.user?.email ?? '';

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        title: const Text(
          'Minhas Metas',
          style: TextStyle(color: Color(0xFF0F172A)),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
      ),
      body: _fetchingProfile
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.blueGrey.shade100,
                        child: Text(
                          userName.isEmpty ? '?' : userName[0],
                          style: const TextStyle(
                            fontSize: 22,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              userEmail,
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildCard(
                    title: 'Seus dados',
                    child: Column(
                      children: [
                        TextField(
                          controller: ageCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Idade',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: weightCtrl,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Peso (kg)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: heightCtrl,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Altura (cm)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildSelectableChip(
                              'Masculino',
                              sex == 'masculino',
                              () => setState(() => sex = 'masculino'),
                            ),
                            _buildSelectableChip(
                              'Feminino',
                              sex == 'feminino',
                              () => setState(() => sex = 'feminino'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _buildCard(
                    title: 'Objetivo',
                    child: Column(
                      children: [
                        Wrap(
                          spacing: 10,
                          children: [
                            _buildSelectableChip(
                              'Perder peso',
                              goal == 'perder',
                              () => setState(() => goal = 'perder'),
                            ),
                            _buildSelectableChip(
                              'Manter',
                              goal == 'manter',
                              () => setState(() => goal = 'manter'),
                            ),
                            _buildSelectableChip(
                              'Ganhar massa',
                              goal == 'ganhar',
                              () => setState(() => goal = 'ganhar'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        DropdownButtonFormField<double>(
                          initialValue: activityLevel,
                          decoration: const InputDecoration(
                            labelText: 'Nivel de atividade',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 1.2,
                              child: Text('Sedentario (1.2)'),
                            ),
                            DropdownMenuItem(
                              value: 1.375,
                              child: Text('Leve (1.375)'),
                            ),
                            DropdownMenuItem(
                              value: 1.55,
                              child: Text('Moderado (1.55)'),
                            ),
                            DropdownMenuItem(
                              value: 1.725,
                              child: Text('Ativo (1.725)'),
                            ),
                            DropdownMenuItem(
                              value: 1.9,
                              child: Text('Extremo (1.9)'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => activityLevel = value);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  if (tmb != null && tdee != null)
                    _buildCard(
                      title: 'Seus indicadores',
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'TMB:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              Text('${tmb!.toStringAsFixed(0)} kcal'),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'TDEE:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              Text('${tdee!.toStringAsFixed(0)} kcal'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  _buildWeightCard(),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: loading ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFA8D0E6),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: loading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Salvar metas',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildWeightCard() {
    final formatter = DateFormat('dd/MM');
    return _buildCard(
      title: 'Registro de peso',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _logWeightCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Peso atual (kg)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: _pickWeightDate,
                child: Text(formatter.format(_weightDate)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _savingWeight ? null : _saveWeightEntry,
              icon: _savingWeight
                  ? const SizedBox(
                      height: 14,
                      width: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.monitor_weight_outlined),
              label: const Text('Registrar peso'),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: _loadingWeights
                ? const Center(child: CircularProgressIndicator())
                : _weightEntries.isEmpty
                    ? const Center(child: Text('Nenhum peso registrado ainda.'))
                    : LineChart(_buildWeightChartData()),
          ),
          const SizedBox(height: 12),
          if (_weightEntries.isNotEmpty)
            Column(
              children: _weightEntries.take(4).map((entry) {
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.fitness_center, size: 20),
                  title: Text('${entry.weight.toStringAsFixed(1)} kg'),
                  subtitle: Text(formatter.format(entry.date)),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  LineChartData _buildWeightChartData() {
    final sorted = List<WeightEntry>.from(_weightEntries)
      ..sort((a, b) => a.date.compareTo(b.date));
    final lastEntries = sorted.takeLast(14).toList();
    final points = lastEntries
        .asMap()
        .entries
        .map((entry) => FlSpot(
              entry.key.toDouble(),
              entry.value.weight,
            ))
        .toList();
    final minY =
        points.fold<double>(points.first.y, (value, spot) => math.min(value, spot.y)) - 2;
    final maxY =
        points.fold<double>(points.first.y, (value, spot) => math.max(value, spot.y)) + 2;

    return LineChartData(
      minX: 0,
      maxX: (points.length - 1).toDouble(),
      minY: minY,
      maxY: maxY,
      gridData: FlGridData(show: false),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: Colors.grey.shade200),
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, meta) => Text(
              value.toStringAsFixed(0),
              style: const TextStyle(fontSize: 11),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= points.length) return const SizedBox.shrink();
              final entry = lastEntries[index];
              return Text(
                DateFormat('dd/MM').format(entry.date),
                style: const TextStyle(fontSize: 10),
              );
            },
          ),
        ),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      lineBarsData: [
        LineChartBarData(
          isCurved: true,
          color: const Color(0xFFA8D0E6),
          barWidth: 3,
          dotData: FlDotData(show: true),
          belowBarData: BarAreaData(
            show: true,
            color: const Color(0xFFA8D0E6).withValues(alpha: 0.2),
          ),
          spots: points,
        ),
      ],
    );
  }
}

extension<T> on List<T> {
  Iterable<T> takeLast(int count) {
    if (length <= count) return this;
    return sublist(length - count);
  }
}
