import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
  final UserService _userService = UserService();

  String sex = 'masculino';
  String goal = 'manter';
  double activityLevel = 1.2;
  double? tmb;
  double? tdee;

  bool loading = false;
  bool _fetchingProfile = false;
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
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

  Widget _buildCard({required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                          value: activityLevel,
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
}
