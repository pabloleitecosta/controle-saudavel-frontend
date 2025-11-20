import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/i18n.dart';
import '../../models/daily_macro_summary.dart';
import '../../models/meal_log.dart';
import '../../models/user_insights.dart';
import '../../models/weight_entry.dart';
import '../../providers/auth_provider.dart';
import '../../services/user_service.dart';

class StatsScreen extends StatefulWidget {
  static const route = '/stats';
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final _userService = UserService();
  Future<_StatsBundle>? _future;
  String? _lastUserId;
  bool _exporting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = Provider.of<AuthProvider>(context);
    final userId = auth.user?.id;
    if (userId != null && userId != _lastUserId) {
      _lastUserId = userId;
      _future = _loadStats(userId);
    }
  }

  Future<_StatsBundle> _loadStats(String userId) async {
    final insights = await _userService.fetchInsights(userId);
    final macros = await _userService.fetchWeeklyMacros(userId);
    final weights = await _userService.fetchWeightHistory(userId, limit: 14);
    return _StatsBundle(
      insights: insights,
      macros: macros,
      weights: weights,
    );
  }

  Future<void> _exportCsv() async {
    final userId = _lastUserId;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entre para exportar o histórico.')),
      );
      return;
    }

    setState(() => _exporting = true);
    try {
      final meals = await _userService.fetchMeals(userId);
      if (meals.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nenhuma refeição registrada ainda.')),
        );
      } else {
        final csv = _mealsToCsv(meals);
        await Share.share(csv, subject: 'Historico Controle Saudavel');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao exportar: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _exporting = false);
      }
    }
  }

  String _mealsToCsv(List<MealLog> meals) {
    final buffer = StringBuffer();
    buffer.writeln(
        'data,origem,calorias,proteina,carboidratos,gorduras,quantidade_itens');
    for (final meal in meals) {
      buffer.writeln(
        '${meal.date},${meal.source},${meal.totalCalories.toStringAsFixed(0)},${meal.totalProtein.toStringAsFixed(1)},${meal.totalCarbs.toStringAsFixed(1)},${meal.totalFat.toStringAsFixed(1)},${meal.items.length}',
      );
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(t.t('stats_title')),
        actions: [
          IconButton(
            onPressed: _exporting ? null : _exportCsv,
            icon: _exporting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.ios_share),
            tooltip: 'Exportar CSV',
          ),
        ],
      ),
      body: _future == null
          ? const Center(
              child: Text('Entre com sua conta para ver os insights.'),
            )
          : FutureBuilder<_StatsBundle>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Erro ao carregar insights: ${snapshot.error}'),
                    ),
                  );
                }
                final data = snapshot.data!;
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildHighlights(data.insights),
                    const SizedBox(height: 16),
                    _buildCaloriesChart(data.macros),
                    const SizedBox(height: 16),
                    _buildWeightChart(data.weights),
                    const SizedBox(height: 16),
                    _buildInsightsList(data.insights),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildHighlights(UserInsights insights) {
    return Row(
      children: [
        Expanded(
          child: Card(
            child: ListTile(
              leading: const Icon(Icons.local_fire_department_outlined),
              title: const Text('Media calorica'),
              subtitle: Text('${insights.avgCalories.toStringAsFixed(0)} kcal'),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Card(
            child: ListTile(
              leading: const Icon(Icons.fitness_center),
              title: const Text('Media proteica'),
              subtitle: Text('${insights.avgProtein.toStringAsFixed(1)} g'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCaloriesChart(List<DailyMacroSummary> macros) {
    final formatter = DateFormat('E', 'pt_BR');
    final groups = macros.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: item.calories,
            color: const Color(0xFFA8D0E6),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            width: 18,
          ),
        ],
      );
    }).toList();

    final maxCalories = macros.isEmpty
        ? 0
        : macros.map((e) => e.calories).reduce(math.max);
    final maxY =
        ((maxCalories * 1.2).clamp(200, double.infinity)) as double;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Calorias nos ultimos 7 dias',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 240,
              child: BarChart(
                BarChartData(
                  maxY: maxY == 0 ? 200 : maxY,
                  borderData: FlBorderData(show: false),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final day = macros[groupIndex];
                        return BarTooltipItem(
                          '${formatter.format(day.date)}\n${rod.toY.toStringAsFixed(0)} kcal',
                          const TextStyle(color: Colors.white),
                        );
                      },
                    ),
                  ),
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 42,
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
                          if (index < 0 || index >= macros.length) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            formatter.format(macros[index].date),
                            style: const TextStyle(fontSize: 11),
                          );
                        },
                      ),
                    ),
                    rightTitles:
                        const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles:
                        const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  barGroups: groups,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightChart(List<WeightEntry> weights) {
    if (weights.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Registre seus pesos para ver a evolucao.'),
        ),
      );
    }

    final sorted = List<WeightEntry>.from(weights)
      ..sort((a, b) => a.date.compareTo(b.date));
    final lastEntries = sorted.takeLast(14).toList();
    final spots = lastEntries
        .asMap()
        .entries
        .map(
          (entry) => FlSpot(
            entry.key.toDouble(),
            entry.value.weight,
          ),
        )
        .toList();

    double minY = spots.first.y;
    double maxY = spots.first.y;
    for (final spot in spots) {
      minY = math.min(minY, spot.y);
      maxY = math.max(maxY, spot.y);
    }
    minY -= 2;
    maxY += 2;

    final formatter = DateFormat('dd/MM');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Evolucao do peso',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: (spots.length - 1).toDouble(),
                  minY: minY,
                  maxY: maxY,
                  gridData: FlGridData(show: false),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= lastEntries.length) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            formatter.format(lastEntries[index].date),
                            style: const TextStyle(fontSize: 11),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 42,
                        getTitlesWidget: (value, meta) => Text(
                          value.toStringAsFixed(0),
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                    rightTitles:
                        const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles:
                        const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      isCurved: true,
                      color: const Color(0xFF5BC0BE),
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFF5BC0BE).withValues(alpha: 0.15),
                      ),
                      spots: spots,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsList(UserInsights insights) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Insights da semana',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (insights.insights.isEmpty)
              const Text(
                  'Ainda nao ha recomendacoes. Registre suas refeicoes para gerar dicas personalizadas.')
            else
              ...insights.insights.map(
                (text) => ListTile(
                  leading: const Icon(Icons.auto_graph),
                  title: Text(text),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatsBundle {
  final UserInsights insights;
  final List<DailyMacroSummary> macros;
  final List<WeightEntry> weights;

  const _StatsBundle({
    required this.insights,
    required this.macros,
    required this.weights,
  });
}

extension<T> on List<T> {
  Iterable<T> takeLast(int count) {
    if (length <= count) return this;
    return sublist(length - count);
  }
}
