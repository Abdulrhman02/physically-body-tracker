import 'dart:io';
import 'package:csv/csv.dart';
import '../models/models.dart';
import 'database_service.dart';

class CsvImportResult {
  final int scansImported;
  final int weightsSeeded;
  final int rowsSkipped;
  CsvImportResult(this.scansImported, this.weightsSeeded, this.rowsSkipped);
}

class CsvImportService {
  /// Parses an InBody export CSV and inserts/upserts each row.
  /// Returns counts. Each unique scan timestamp is a row.
  static Future<CsvImportResult> importInBodyCsv(File file) async {
    final raw = await file.readAsString();
    // InBody export uses \r\n; csv pkg handles either.
    final rows = const CsvToListConverter(
      eol: '\n',
      shouldParseNumbers: false,
    ).convert(raw);
    if (rows.isEmpty) return CsvImportResult(0, 0, 0);

    // Strip BOM from first cell if present.
    rows.first[0] = rows.first[0].toString().replaceAll('\uFEFF', '');
    final header = rows.first.map((e) => e.toString().trim()).toList();
    int idx(String name) => header.indexWhere((h) => h == name);

    final i = {
      'date': idx('Date'),
      'weight': idx('Weight(kg)'),
      'smm': idx('Skeletal Muscle Mass(kg)'),
      'bfm': idx('Body Fat Mass(kg)'),
      'bmi': idx('BMI(kg/m²)'),
      'pbf': idx('Percent Body Fat(%)'),
      'bmr': idx('Basal Metabolic Rate(kcal)'),
      'score': idx('InBody Score'),
      'rArmLean': idx('Right Arm Lean Mass(kg)'),
      'lArmLean': idx('Left Arm Lean Mass(kg)'),
      'trunkLean': idx('Trunk Lean Mass(kg)'),
      'rLegLean': idx('Right Leg Lean Mass(kg)'),
      'lLegLean': idx('Left leg Lean Mass(kg)'),
      'rArmFat': idx('Right Arm Fat Mass(kg)'),
      'lArmFat': idx('Left Arm Fat Mass(kg)'),
      'trunkFat': idx('Trunk Fat Mass(kg)'),
      'rLegFat': idx('Right Leg Fat Mass(kg)'),
      'lLegFat': idx('Left Leg Fat Mass(kg)'),
      'whr': idx('Waist Hip Ratio'),
      'vfl': idx('Visceral Fat Level(Level)'),
      'tbw': idx('Total Body Water(L)'),
      'protein': idx('Protein(kg)'),
      'mineral': idx('Mineral(kg)'),
      'smi': idx('SMI(kg/m²)'),
    };

    int imported = 0, weights = 0, skipped = 0;
    for (int r = 1; r < rows.length; r++) {
      final row = rows[r];
      if (row.isEmpty || (row.length == 1 && row.first.toString().trim().isEmpty)) {
        continue;
      }
      if (i['date']! < 0 || i['date']! >= row.length) { skipped++; continue; }
      final dateStr = row[i['date']!].toString();
      final date = _parseInBodyDate(dateStr);
      if (date == null) { skipped++; continue; }

      final scan = InBodyScan(
        takenAt: date,
        weightKg: _d(row, i['weight']),
        skeletalMuscleMassKg: _d(row, i['smm']),
        bodyFatMassKg: _d(row, i['bfm']),
        bmi: _d(row, i['bmi']),
        percentBodyFat: _d(row, i['pbf']),
        bmrKcal: _d(row, i['bmr']),
        inBodyScore: _d(row, i['score']),
        rightArmLeanKg: _d(row, i['rArmLean']),
        leftArmLeanKg: _d(row, i['lArmLean']),
        trunkLeanKg: _d(row, i['trunkLean']),
        rightLegLeanKg: _d(row, i['rLegLean']),
        leftLegLeanKg: _d(row, i['lLegLean']),
        rightArmFatKg: _d(row, i['rArmFat']),
        leftArmFatKg: _d(row, i['lArmFat']),
        trunkFatKg: _d(row, i['trunkFat']),
        rightLegFatKg: _d(row, i['rLegFat']),
        leftLegFatKg: _d(row, i['lLegFat']),
        waistHipRatio: _d(row, i['whr']),
        visceralFatLevel: _d(row, i['vfl']),
        totalBodyWaterL: _d(row, i['tbw']),
        proteinKg: _d(row, i['protein']),
        mineralKg: _d(row, i['mineral']),
        smiKgM2: _d(row, i['smi']),
      );
      await DatabaseService.instance.upsertInBody(scan);
      imported++;

      if (scan.weightKg != null) {
        await DatabaseService.instance.insertWeight(
          WeightEntry(kg: scan.weightKg!, takenAt: date, note: 'InBody import'),
        );
        weights++;
      }
    }
    return CsvImportResult(imported, weights, skipped);
  }

  static double? _d(List row, int? idx) {
    if (idx == null || idx < 0 || idx >= row.length) return null;
    final v = row[idx].toString().trim();
    if (v.isEmpty || v == '-' || v == 'Etc' || v == 'N/A') return null;
    return double.tryParse(v);
  }

  /// InBody dates: `20260408124216` -> 2026-04-08 12:42:16
  static DateTime? _parseInBodyDate(String s) {
    s = s.trim();
    if (s.length < 8) return null;
    try {
      final y = int.parse(s.substring(0, 4));
      final mo = int.parse(s.substring(4, 6));
      final d = int.parse(s.substring(6, 8));
      final h = s.length >= 10 ? int.parse(s.substring(8, 10)) : 0;
      final mi = s.length >= 12 ? int.parse(s.substring(10, 12)) : 0;
      final se = s.length >= 14 ? int.parse(s.substring(12, 14)) : 0;
      // Sanity check year.
      if (y < 1970 || y > 2100) return null;
      return DateTime(y, mo, d, h, mi, se);
    } catch (_) {
      return null;
    }
  }
}
