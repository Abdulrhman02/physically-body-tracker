import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../widgets/body_diagram.dart';
import '../widgets/trend_chart.dart';

class BodyScreen extends StatefulWidget {
  const BodyScreen({super.key});
  @override
  State<BodyScreen> createState() => _BodyScreenState();
}

class _BodyScreenState extends State<BodyScreen> {
  Map<BodyPart, Measurement?> _latest = {};
  Map<BodyPart, double?> _deltas = {};
  double? _latestWeight;
  double? _weightDelta;
  double? _bmi;
  double? _bodyFatPct;
  double? _muscleKg;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final db = DatabaseService.instance;
    final latest = await db.latestPerPart();
    final deltas = <BodyPart, double?>{};
    for (final p in BodyPart.values) {
      final all = await db.measurementsFor(p);
      deltas[p] = all.length >= 2
          ? all.last.valueCm - all[all.length - 2].valueCm
          : null;
    }
    final weights = await db.allWeights();
    final ib = await db.latestInBody();

    double? wDelta;
    if (weights.length >= 2) {
      wDelta = weights.last.kg - weights[weights.length - 2].kg;
    }

    if (!mounted) return;
    setState(() {
      _latest = latest;
      _deltas = deltas;
      _latestWeight = weights.isEmpty ? null : weights.last.kg;
      _weightDelta = wDelta;
      _bmi = ib?.bmi;
      _bodyFatPct = ib?.percentBodyFat;
      _muscleKg = ib?.skeletalMuscleMassKg;
      _loading = false;
    });
  }

  Future<void> _openInput(BodyPart part) async {
    final controller = TextEditingController(
      text: _latest[part]?.valueCm.toStringAsFixed(1) ?? '',
    );
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(part.label, style: Theme.of(ctx).textTheme.titleLarge),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx, false),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Measurement (cm)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<Measurement>>(
                future: DatabaseService.instance.measurementsFor(part),
                builder: (ctx, snap) {
                  final list = snap.data ?? const [];
                  final pts = [
                    for (final m in list) MapEntry(m.takenAt, m.valueCm),
                  ];
                  return TrendChart(
                    points: pts,
                    title: '${part.label} history',
                    unit: 'cm',
                    color: AppTheme.muscle,
                    height: 160,
                  );
                },
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<Measurement>>(
                future: DatabaseService.instance.measurementsFor(part),
                builder: (ctx, snap) {
                  final list =
                      (snap.data ?? const []).reversed.take(5).toList();
                  if (list.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Recent entries',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      ...list.map((m) => Row(
                            children: [
                              Text(DateFormat('MMM d, y').format(m.takenAt),
                                  style: const TextStyle(fontSize: 12)),
                              const Spacer(),
                              Text('${m.valueCm.toStringAsFixed(1)} cm',
                                  style: const TextStyle(fontSize: 12)),
                              IconButton(
                                iconSize: 18,
                                icon: const Icon(Icons.delete_outline),
                                onPressed: m.id == null
                                    ? null
                                    : () async {
                                        await DatabaseService.instance
                                            .deleteMeasurement(m.id!);
                                        if (ctx.mounted) {
                                          Navigator.pop(ctx, true);
                                        }
                                      },
                              ),
                            ],
                          )),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Spacer(),
                  FilledButton(
                    onPressed: () async {
                      final v =
                          double.tryParse(controller.text.replaceAll(',', '.'));
                      if (v == null || v <= 0) return;
                      await DatabaseService.instance.insertMeasurement(
                        Measurement(
                            part: part, valueCm: v, takenAt: DateTime.now()),
                      );
                      if (ctx.mounted) Navigator.pop(ctx, true);
                    },
                    child: const Text('Save measurement'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
    if (saved == true) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: BodyDiagram(
                latest: _latest,
                deltas: _deltas,
                onTap: _openInput,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _statTile(
            label: 'BODYWEIGHT',
            value: _latestWeight == null
                ? '—'
                : '${_latestWeight!.toStringAsFixed(1)} kg',
            delta: _weightDelta == null
                ? null
                : '${_weightDelta! >= 0 ? '+' : ''}${_weightDelta!.toStringAsFixed(1)} kg',
            icon: Icons.monitor_weight,
            color: Colors.blueGrey,
          ),
          _statTile(
            label: 'MUSCLE MASS',
            value:
                _muscleKg == null ? '—' : '${_muscleKg!.toStringAsFixed(1)} kg',
            icon: Icons.fitness_center,
            color: AppTheme.muscle,
          ),
          _statTile(
            label: 'BODY FAT',
            value: _bodyFatPct == null
                ? '—'
                : '${_bodyFatPct!.toStringAsFixed(1)} %',
            icon: Icons.water_drop,
            color: AppTheme.fat,
          ),
          _statTile(
            label: 'BMI',
            value: _bmi?.toStringAsFixed(1) ?? '—',
            icon: Icons.speed,
            color: _bmi == null
                ? Colors.grey
                : (_bmi! >= 30
                    ? AppTheme.danger
                    : _bmi! >= 25
                        ? Colors.orange
                        : AppTheme.positive),
          ),
          const SizedBox(height: 8),
          Text('Tap any marker or label to add or update a measurement.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _statTile({
    required String label,
    required String value,
    String? delta,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(label,
            style: const TextStyle(fontSize: 11, letterSpacing: 0.5)),
        subtitle: Text(value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        trailing: delta == null
            ? null
            : Text(delta,
                style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.muscle,
                    fontWeight: FontWeight.w600)),
      ),
    );
  }
}
