import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/database_service.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  UserProfile _p = const UserProfile();
  late final TextEditingController _name;
  late final TextEditingController _age;
  late final TextEditingController _height;
  late final TextEditingController _activity;
  late final TextEditingController _notes;
  Sex? _sex;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
    _age = TextEditingController();
    _height = TextEditingController();
    _activity = TextEditingController();
    _notes = TextEditingController();
    _load();
  }

  Future<void> _load() async {
    final p = await ProfileService.instance.load();
    setState(() {
      _p = p;
      _name.text = p.name ?? '';
      _age.text = p.ageYears?.toString() ?? '';
      _height.text = p.heightCm?.toString() ?? '';
      _activity.text = p.activityLevel ?? '';
      _notes.text = p.notes ?? '';
      _sex = p.sex;
      _loading = false;
    });
  }

  Future<void> _save() async {
    final updated = _p.copyWith(
      name: _name.text.trim(),
      ageYears: int.tryParse(_age.text.trim()),
      sex: _sex,
      heightCm: double.tryParse(_height.text.replaceAll(',', '.')),
      activityLevel: _activity.text.trim(),
      notes: _notes.text.trim(),
    );
    await ProfileService.instance.save(updated);
    if (!mounted) return;
    setState(() => _p = updated);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile saved')),
    );
  }

  Future<void> _wipeData() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete all data?'),
        content: const Text(
            'This permanently deletes all measurements, weights, and imported '
            'InBody scans. Profile settings are kept. Cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete everything')),
        ],
      ),
    );
    if (ok == true) {
      await DatabaseService.instance.wipeAll();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All data deleted')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Your profile',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  'Used to personalize the LLM prompt (height → BMI context, '
                  'age/sex → calorie & protein recommendations).',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _name,
                  decoration: const InputDecoration(
                      labelText: 'Name (optional)',
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _age,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: 'Age', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<Sex>(
                        initialValue: _sex,
                        decoration: const InputDecoration(
                            labelText: 'Sex', border: OutlineInputBorder()),
                        items: Sex.values
                            .map((s) =>
                                DropdownMenuItem(value: s, child: Text(s.name)))
                            .toList(),
                        onChanged: (v) => setState(() => _sex = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _height,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                      labelText: 'Height (cm)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _activity,
                  decoration: const InputDecoration(
                      labelText:
                          'Activity level (e.g. "lift 4x/week, walk daily")',
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _notes,
                  maxLines: 3,
                  decoration: const InputDecoration(
                      labelText:
                          'Notes for the coach (dietary restrictions, injuries…)',
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save),
                    label: const Text('Save profile'),
                  ),
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
                const Text('Data management',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading:
                      const Icon(Icons.delete_forever, color: AppTheme.danger),
                  title: const Text('Delete all tracked data'),
                  subtitle: const Text('Measurements, weights, InBody scans'),
                  onTap: _wipeData,
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
                const Text('About',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                const Text('Body Tracker · v1.0'),
                const SizedBox(height: 4),
                Text(
                  'All data stays on your device. Use the Prompt tab to '
                  'export a snapshot for any LLM.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
