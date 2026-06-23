import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../models/models.dart';
import '../services/database_service.dart';
import '../services/profile_service.dart';
import '../services/prompt_builder.dart';
import '../theme/app_theme.dart';

class PromptScreen extends StatefulWidget {
  const PromptScreen({super.key});
  @override
  State<PromptScreen> createState() => _PromptScreenState();
}

class _PromptScreenState extends State<PromptScreen> {
  UserProfile _profile = const UserProfile();
  List<InBodyScan> _inbody = [];
  List<WeightEntry> _weights = [];
  Map<BodyPart, List<Measurement>> _circ = {};
  String _prompt = '';
  bool _loading = true;

  int _scanCount = 10;
  int _weightCount = 10;
  bool _segmental = true;
  bool _circumferences = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await ProfileService.instance.load();
    final ib = await DatabaseService.instance.allInBody();
    final ws = await DatabaseService.instance.allWeights();
    final cr = await DatabaseService.instance.allMeasurementsByPart();
    if (!mounted) return;
    setState(() {
      _profile = p;
      _inbody = ib;
      _weights = ws;
      _circ = cr;
      _loading = false;
    });
    _rebuild();
  }

  void _rebuild() {
    final prompt = PromptBuilder.build(
      profile: _profile,
      inbody: _inbody,
      weights: _weights,
      circumferences: _circ,
      options: PromptOptions(
        recentScanCount: _scanCount,
        recentWeightCount: _weightCount,
        includeSegmental: _segmental,
        includeCircumferences: _circumferences,
      ),
    );
    setState(() => _prompt = prompt);
  }

  Future<void> _editGoal() async {
    final goal = TextEditingController(text: _profile.goal);
    final tw =
        TextEditingController(text: _profile.targetWeightKg?.toString() ?? '');
    final tbf = TextEditingController(
        text: _profile.targetBodyFatPct?.toString() ?? '');
    final td = TextEditingController(text: _profile.targetDate ?? '');

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit goal'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: goal,
                maxLines: 2,
                decoration: const InputDecoration(
                    labelText: 'Primary goal', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: tw,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                    labelText: 'Target weight (kg)',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: tbf,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                    labelText: 'Target body fat (%)',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: td,
                decoration: const InputDecoration(
                    labelText: 'Target date (e.g. 2026-09-01 or "in 3 months")',
                    border: OutlineInputBorder()),
              ),
            ],
          ),
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
    final updated = _profile.copyWith(
      goal: goal.text.trim().isEmpty ? _profile.goal : goal.text.trim(),
      targetWeightKg: double.tryParse(tw.text.replaceAll(',', '.')),
      targetBodyFatPct: double.tryParse(tbf.text.replaceAll(',', '.')),
      targetDate: td.text.trim().isEmpty ? null : td.text.trim(),
    );
    await ProfileService.instance.save(updated);
    setState(() => _profile = updated);
    _rebuild();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final hasData = _inbody.isNotEmpty ||
        _weights.isNotEmpty ||
        _circ.values.any((e) => e.isNotEmpty);

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.flag_outlined),
                    const SizedBox(width: 8),
                    const Text('Goal',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _editGoal,
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Edit'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(_profile.goal),
                if (_profile.targetWeightKg != null ||
                    _profile.targetBodyFatPct != null ||
                    (_profile.targetDate?.isNotEmpty ?? false)) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: [
                      if (_profile.targetWeightKg != null)
                        Chip(
                            label:
                                Text('Target: ${_profile.targetWeightKg} kg')),
                      if (_profile.targetBodyFatPct != null)
                        Chip(
                            label: Text(
                                'Body fat: ${_profile.targetBodyFatPct}%')),
                      if (_profile.targetDate?.isNotEmpty ?? false)
                        Chip(label: Text('By: ${_profile.targetDate}')),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.tune),
                    SizedBox(width: 8),
                    Text('What to include',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 4),
                _slider(
                  'Recent InBody scans',
                  _scanCount.toDouble(),
                  1,
                  30,
                  (v) {
                    setState(() => _scanCount = v.round());
                    _rebuild();
                  },
                ),
                _slider(
                  'Recent weight entries',
                  _weightCount.toDouble(),
                  1,
                  30,
                  (v) {
                    setState(() => _weightCount = v.round());
                    _rebuild();
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Include segmental breakdown'),
                  subtitle: const Text('Lean/fat per arm, leg, trunk'),
                  value: _segmental,
                  onChanged: (v) {
                    setState(() => _segmental = v);
                    _rebuild();
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Include circumference measurements'),
                  value: _circumferences,
                  onChanged: (v) {
                    setState(() => _circumferences = v);
                    _rebuild();
                  },
                ),
              ],
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.description_outlined),
                    const SizedBox(width: 8),
                    const Text('Prompt preview',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    const Spacer(),
                    Text('${_prompt.length} chars',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade600)),
                  ],
                ),
                const SizedBox(height: 8),
                if (!hasData)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: const Text(
                      'No data found yet. Import an InBody CSV or add weight / '
                      'body measurements to build a useful prompt.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4EE),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: SelectableText(
                    _prompt,
                    style: const TextStyle(
                        fontSize: 12, height: 1.4, fontFamily: 'monospace'),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          await Clipboard.setData(ClipboardData(text: _prompt));
                          if (!mounted) return;
                          messenger.showSnackBar(
                            const SnackBar(
                                content: Text('Prompt copied to clipboard')),
                          );
                        },
                        icon: const Icon(Icons.copy),
                        label: const Text('Copy'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Share.share(_prompt,
                              subject: 'Body composition prompt');
                        },
                        icon: const Icon(Icons.share),
                        label: const Text('Share'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Paste this into Claude, ChatGPT, Gemini, or any other LLM. '
                  'It includes your profile, goal, InBody history, weight log, '
                  'and circumference data — formatted so the model can give '
                  'you specific, data-grounded coaching.',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _slider(String label, double v, double min, double max,
      ValueChanged<double> onChange) {
    return Row(
      children: [
        SizedBox(
          width: 160,
          child: Text('$label: ${v.round()}',
              style: const TextStyle(fontSize: 13)),
        ),
        Expanded(
          child: Slider(
            value: v,
            min: min,
            max: max,
            divisions: (max - min).round(),
            activeColor: AppTheme.dark,
            onChanged: onChange,
          ),
        ),
      ],
    );
  }
}
