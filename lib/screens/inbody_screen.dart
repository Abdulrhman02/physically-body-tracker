import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/csv_import_service.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../widgets/trend_chart.dart';

class InBodyScreen extends StatefulWidget {
  const InBodyScreen({super.key});
  @override
  State<InBodyScreen> createState() => _InBodyScreenState();
}

class _InBodyScreenState extends State<InBodyScreen> {
  List<InBodyScan> _scans = [];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final list = await DatabaseService.instance.allInBody();
    if (!mounted) return;
    setState(() => _scans = list);
  }

  Future<void> _import() async {
    try {
      final res = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
      if (res == null || res.files.single.path == null) return;
      if (!mounted) return;
      setState(() => _busy = true);
      final r =
          await CsvImportService.importInBodyCsv(File(res.files.single.path!));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Imported ${r.scansImported} scans · '
              '${r.weightsSeeded} weight entries'
              '${r.rowsSkipped > 0 ? " · ${r.rowsSkipped} skipped" : ""}'),
        ),
      );
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmDelete(InBodyScan s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete scan?'),
        content: Text(DateFormat('MMM d, y HH:mm').format(s.takenAt)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true && s.id != null) {
      await DatabaseService.instance.deleteInBody(s.id!);
      _refresh();
    }
  }

  List<MapEntry<DateTime, double>> _series(double? Function(InBodyScan) f) {
    final out = <MapEntry<DateTime, double>>[];
    for (final s in _scans) {
      final v = f(s);
      if (v != null) out.add(MapEntry(s.takenAt, v));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final latest = _scans.isEmpty ? null : _scans.last;
    final fmt = DateFormat('MMM d, y');

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _busy ? null : _import,
        backgroundColor: AppTheme.accent,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.upload_file),
        label: Text(_busy ? 'Importing…' : 'Import InBody CSV'),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            if (latest == null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(Icons.analytics,
                          size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      const Text('No InBody data yet',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      const Text(
                        'Tap "Import InBody CSV" to load your scans.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.event, size: 16),
                          const SizedBox(width: 6),
                          Text('Latest scan · ${fmt.format(latest.takenAt)}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                          const Spacer(),
                          Text('${_scans.length} total',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade600)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          _stat('Weight', latest.weightKg, 'kg'),
                          _stat('Muscle', latest.skeletalMuscleMassKg, 'kg',
                              AppTheme.muscle),
                          _stat('Body fat', latest.bodyFatMassKg, 'kg',
                              AppTheme.fat),
                          _stat(
                              'PBF', latest.percentBodyFat, '%', AppTheme.fat),
                          _stat('BMI', latest.bmi, ''),
                          _stat('BMR', latest.bmrKcal, 'kcal'),
                          _stat('Visceral', latest.visceralFatLevel, 'lvl',
                              AppTheme.danger),
                          _stat('TBW', latest.totalBodyWaterL, 'L',
                              AppTheme.water),
                          _stat('Score', latest.inBodyScore, ''),
                          _stat('WHR', latest.waistHipRatio, '', Colors.brown),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _chartCard(
                  'Weight', _series((s) => s.weightKg), 'kg', Colors.blueGrey),
              _chartCard(
                  'Skeletal muscle mass',
                  _series((s) => s.skeletalMuscleMassKg),
                  'kg',
                  AppTheme.muscle),
              _chartCard('Body fat mass', _series((s) => s.bodyFatMassKg), 'kg',
                  AppTheme.fat),
              _chartCard('Body fat %', _series((s) => s.percentBodyFat), '%',
                  AppTheme.fat),
              _chartCard('Visceral fat level',
                  _series((s) => s.visceralFatLevel), 'lvl', AppTheme.danger),
              _chartCard('BMI', _series((s) => s.bmi), '', Colors.deepPurple),
              _chartCard('InBody score', _series((s) => s.inBodyScore), '',
                  AppTheme.positive),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Text('All scans',
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              ..._scans.reversed.map((s) => Card(
                    child: ListTile(
                      title:
                          Text(DateFormat('MMM d, y HH:mm').format(s.takenAt)),
                      subtitle: Text(
                        '${s.weightKg?.toStringAsFixed(1) ?? "—"} kg · '
                        'SMM ${s.skeletalMuscleMassKg?.toStringAsFixed(1) ?? "—"} · '
                        'BFM ${s.bodyFatMassKg?.toStringAsFixed(1) ?? "—"} · '
                        'PBF ${s.percentBodyFat?.toStringAsFixed(1) ?? "—"}%',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _confirmDelete(s),
                      ),
                    ),
                  )),
              const SizedBox(height: 80),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chartCard(String title, List<MapEntry<DateTime, double>> pts,
      String unit, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: TrendChart(points: pts, title: title, unit: unit, color: color),
      ),
    );
  }

  Widget _stat(String label, double? v, String unit,
      [Color color = Colors.black87]) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade700)),
          Text(v == null ? '—' : '${v.toStringAsFixed(1)} $unit',
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}
