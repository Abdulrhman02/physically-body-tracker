import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../widgets/trend_chart.dart';

class WeightScreen extends StatefulWidget {
  const WeightScreen({super.key});
  @override
  State<WeightScreen> createState() => _WeightScreenState();
}

class _WeightScreenState extends State<WeightScreen> {
  List<WeightEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final list = await DatabaseService.instance.allWeights();
    if (!mounted) return;
    setState(() => _entries = list);
  }

  Future<void> _add() async {
    final c = TextEditingController();
    final note = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add weight'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: c,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration:
                  const InputDecoration(suffixText: 'kg', labelText: 'Weight'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: note,
              decoration: const InputDecoration(labelText: 'Note (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save')),
        ],
      ),
    );
    if (ok != true) return;
    final v = double.tryParse(c.text.replaceAll(',', '.'));
    if (v == null || v <= 0) return;
    await DatabaseService.instance.insertWeight(
      WeightEntry(
          kg: v,
          takenAt: DateTime.now(),
          note: note.text.isEmpty ? null : note.text),
    );
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final pts = [for (final w in _entries) MapEntry(w.takenAt, w.kg)];
    final fmt = DateFormat('MMM d, y · HH:mm');

    double? last, delta;
    if (_entries.isNotEmpty) {
      last = _entries.last.kg;
      if (_entries.length >= 2) {
        delta = last - _entries[_entries.length - 2].kg;
      }
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _add,
        backgroundColor: AppTheme.accent,
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            if (last != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Current', style: TextStyle(fontSize: 11)),
                          Text('${last.toStringAsFixed(1)} kg',
                              style: const TextStyle(
                                  fontSize: 28, fontWeight: FontWeight.w800)),
                        ],
                      ),
                      const Spacer(),
                      if (delta != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Since previous entry',
                                style: TextStyle(fontSize: 11)),
                            Text(
                              '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)} kg',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: delta <= 0
                                      ? AppTheme.positive
                                      : AppTheme.danger),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: TrendChart(
                  points: pts,
                  title: 'Weight (kg)',
                  unit: 'kg',
                  color: Colors.blueGrey,
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (_entries.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('Tap + to add your first entry')),
              ),
            ..._entries.reversed.map((w) => Card(
                  child: ListTile(
                    title: Text('${w.kg.toStringAsFixed(1)} kg'),
                    subtitle: Text(
                      '${fmt.format(w.takenAt)}'
                      '${w.note != null && w.note!.isNotEmpty ? " · ${w.note}" : ""}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        if (w.id == null) return;
                        await DatabaseService.instance.deleteWeight(w.id!);
                        _refresh();
                      },
                    ),
                  ),
                )),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
