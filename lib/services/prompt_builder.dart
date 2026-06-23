import 'package:intl/intl.dart';
import '../models/models.dart';

class PromptOptions {
  final int recentScanCount;
  final int recentWeightCount;
  final bool includeSegmental;
  final bool includeCircumferences;
  final bool includeRawJson;

  const PromptOptions({
    this.recentScanCount = 10,
    this.recentWeightCount = 10,
    this.includeSegmental = true,
    this.includeCircumferences = true,
    this.includeRawJson = false,
  });
}

class PromptBuilder {
  static final _date = DateFormat('yyyy-MM-dd');
  static final _dateTime = DateFormat('yyyy-MM-dd HH:mm');

  static String build({
    required UserProfile profile,
    required List<InBodyScan> inbody,
    required List<WeightEntry> weights,
    required Map<BodyPart, List<Measurement>> circumferences,
    PromptOptions options = const PromptOptions(),
  }) {
    final buf = StringBuffer();

    // Role + instructions
    buf.writeln('You are an expert body-composition and fitness coach.');
    buf.writeln('I will share my profile, my goal, and a snapshot of my body '
        'composition history (from InBody 270 scans), my weight log, and my '
        'circumference measurements. Please:');
    buf.writeln(
        '  1. Summarize the trends you see (weight, lean mass, fat mass, '
        'visceral fat, body fat %).');
    buf.writeln('  2. Tell me whether I am on track for my goal, and at the '
        'current rate, when I would realistically reach it.');
    buf.writeln(
        '  3. Recommend a concrete plan: training focus, weekly calorie '
        'and protein targets, and 2–3 specific behavior changes.');
    buf.writeln('  4. Flag any concerning patterns (e.g. muscle loss, plateau, '
        'imbalances between left and right).');
    buf.writeln(
        '  5. Tell me what to track next so future check-ins are useful.');
    buf.writeln();

    // Profile
    buf.writeln('## My profile');
    buf.writeln('- Date of this prompt: ${_date.format(DateTime.now())}');
    if (profile.name != null && profile.name!.isNotEmpty) {
      buf.writeln('- Name: ${profile.name}');
    }
    if (profile.ageYears != null) buf.writeln('- Age: ${profile.ageYears}');
    if (profile.sex != null) buf.writeln('- Sex: ${profile.sex!.name}');
    if (profile.heightCm != null) {
      buf.writeln('- Height: ${profile.heightCm!.toStringAsFixed(0)} cm');
    }
    if (profile.activityLevel != null && profile.activityLevel!.isNotEmpty) {
      buf.writeln('- Activity level: ${profile.activityLevel}');
    }
    if (profile.notes != null && profile.notes!.isNotEmpty) {
      buf.writeln('- Other notes: ${profile.notes}');
    }
    buf.writeln();

    // Goal
    buf.writeln('## My goal');
    buf.writeln('- Primary goal: ${profile.goal}');
    if (profile.targetWeightKg != null) {
      buf.writeln('- Target weight: ${profile.targetWeightKg} kg');
    }
    if (profile.targetBodyFatPct != null) {
      buf.writeln('- Target body fat: ${profile.targetBodyFatPct}%');
    }
    if (profile.targetDate != null && profile.targetDate!.isNotEmpty) {
      buf.writeln('- Target date: ${profile.targetDate}');
    }
    buf.writeln();

    // InBody trend
    if (inbody.isNotEmpty) {
      final recent = _tail(inbody, options.recentScanCount);
      final first = recent.first;
      final last = recent.last;
      final span = last.takenAt.difference(first.takenAt).inDays;
      buf.writeln('## InBody composition history (last ${recent.length} scans, '
          'spanning $span days)');
      buf.writeln();
      buf.writeln(
          '| Date | Weight kg | SMM kg | BFM kg | PBF % | BMI | Visc | TBW L | Score |');
      buf.writeln(
          '|------|-----------|--------|--------|-------|-----|------|-------|-------|');
      for (final s in recent) {
        buf.writeln('| ${_date.format(s.takenAt)} '
            '| ${_n(s.weightKg)} '
            '| ${_n(s.skeletalMuscleMassKg)} '
            '| ${_n(s.bodyFatMassKg)} '
            '| ${_n(s.percentBodyFat)} '
            '| ${_n(s.bmi)} '
            '| ${_n(s.visceralFatLevel, 0)} '
            '| ${_n(s.totalBodyWaterL)} '
            '| ${_n(s.inBodyScore, 0)} |');
      }
      buf.writeln();

      // Deltas
      if (recent.length >= 2) {
        final previous = recent[recent.length - 2];
        buf.writeln('### Change since previous scan');
        _delta(buf, 'Weight', previous.weightKg, last.weightKg, 'kg');
        _delta(buf, 'Skeletal Muscle Mass', previous.skeletalMuscleMassKg,
            last.skeletalMuscleMassKg, 'kg');
        _delta(buf, 'Body Fat Mass', previous.bodyFatMassKg, last.bodyFatMassKg,
            'kg');
        _delta(buf, 'Body Fat %', previous.percentBodyFat, last.percentBodyFat,
            '%');
        _delta(buf, 'BMI', previous.bmi, last.bmi, '');
        _delta(buf, 'Visceral Fat Level', previous.visceralFatLevel,
            last.visceralFatLevel, '');
        _delta(buf, 'BMR', previous.bmrKcal, last.bmrKcal, 'kcal');
        buf.writeln();
      }

      if (options.includeSegmental) {
        buf.writeln('### Latest segmental composition');
        buf.writeln('Lean mass (kg): R-arm ${_n(last.rightArmLeanKg)}, '
            'L-arm ${_n(last.leftArmLeanKg)}, '
            'Trunk ${_n(last.trunkLeanKg)}, '
            'R-leg ${_n(last.rightLegLeanKg)}, '
            'L-leg ${_n(last.leftLegLeanKg)}.');
        buf.writeln('Fat mass (kg): R-arm ${_n(last.rightArmFatKg)}, '
            'L-arm ${_n(last.leftArmFatKg)}, '
            'Trunk ${_n(last.trunkFatKg)}, '
            'R-leg ${_n(last.rightLegFatKg)}, '
            'L-leg ${_n(last.leftLegFatKg)}.');
        if (last.waistHipRatio != null) {
          buf.writeln('Waist-Hip Ratio: ${_n(last.waistHipRatio, 2)}');
        }
        if (last.proteinKg != null || last.mineralKg != null) {
          buf.writeln('Protein: ${_n(last.proteinKg)} kg, '
              'Mineral: ${_n(last.mineralKg)} kg');
        }
        if (last.smiKgM2 != null) {
          buf.writeln(
              'Skeletal Muscle Index (SMI): ${_n(last.smiKgM2, 2)} kg/m²');
        }
        buf.writeln();
      }
    }

    // Weight log
    if (weights.isNotEmpty) {
      final recent = _tail(weights, options.recentWeightCount);
      buf.writeln('## Recent weight log (last ${recent.length} entries)');
      for (final w in recent) {
        buf.writeln('- ${_dateTime.format(w.takenAt)}: '
            '${w.kg.toStringAsFixed(1)} kg'
            '${w.note != null && w.note!.isNotEmpty ? "  (${w.note})" : ""}');
      }
      buf.writeln();
    }

    // Circumferences
    if (options.includeCircumferences) {
      final hasAny = circumferences.values.any((list) => list.isNotEmpty);
      if (hasAny) {
        buf.writeln('## Body circumference measurements (cm)');
        buf.writeln();
        buf.writeln('| Body part | Latest | Previous | Change |');
        buf.writeln('|-----------|--------|----------|--------|');
        for (final part in BodyPart.values) {
          final list = circumferences[part] ?? const [];
          if (list.isEmpty) continue;
          final last = list.last;
          final prev = list.length >= 2 ? list[list.length - 2] : null;
          final dPrev = prev == null ? null : last.valueCm - prev.valueCm;
          buf.writeln('| ${part.label} '
              '| ${last.valueCm.toStringAsFixed(1)} '
              '| ${prev == null ? "—" : prev.valueCm.toStringAsFixed(1)} '
              '| ${_signed(dPrev)} |');
        }
        buf.writeln();
      }
    }

    // Question
    buf.writeln('## My question for you');
    buf.writeln('Please analyze the data above and respond following the 5 '
        'points I listed at the top. Be specific, cite numbers from my data, '
        'and be honest with me — including telling me if my expectations are '
        'unrealistic for the timeframe.');

    return buf.toString();
  }

  static List<T> _tail<T>(List<T> xs, int n) =>
      xs.length <= n ? xs : xs.sublist(xs.length - n);

  static String _n(double? v, [int dp = 1]) =>
      v == null ? '—' : v.toStringAsFixed(dp);

  static String _signed(double? v) {
    if (v == null) return '—';
    final s = v >= 0 ? '+' : '';
    return '$s${v.toStringAsFixed(1)}';
  }

  static void _delta(
      StringBuffer buf, String label, double? a, double? b, String unit) {
    if (a == null || b == null) return;
    final d = b - a;
    final sign = d >= 0 ? '+' : '';
    buf.writeln('- $label: ${a.toStringAsFixed(1)} → '
        '${b.toStringAsFixed(1)} $unit  ($sign${d.toStringAsFixed(1)} $unit)');
  }
}
