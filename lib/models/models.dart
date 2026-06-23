enum BodyPart {
  neck,
  shoulders,
  chest,
  leftBicep,
  rightBicep,
  leftForearm,
  rightForearm,
  waist,
  hips,
  leftThigh,
  rightThigh,
  leftCalf,
  rightCalf,
}

extension BodyPartX on BodyPart {
  String get label {
    switch (this) {
      case BodyPart.neck: return 'Neck';
      case BodyPart.shoulders: return 'Shoulders';
      case BodyPart.chest: return 'Chest';
      case BodyPart.leftBicep: return 'Left Bicep';
      case BodyPart.rightBicep: return 'Right Bicep';
      case BodyPart.leftForearm: return 'Left Forearm';
      case BodyPart.rightForearm: return 'Right Forearm';
      case BodyPart.waist: return 'Waist';
      case BodyPart.hips: return 'Hips';
      case BodyPart.leftThigh: return 'Left Thigh';
      case BodyPart.rightThigh: return 'Right Thigh';
      case BodyPart.leftCalf: return 'Left Calf';
      case BodyPart.rightCalf: return 'Right Calf';
    }
  }

  String get key => name;
}

class Measurement {
  final int? id;
  final BodyPart part;
  final double valueCm;
  final DateTime takenAt;
  final String? note;

  Measurement({
    this.id,
    required this.part,
    required this.valueCm,
    required this.takenAt,
    this.note,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'part': part.key,
    'value_cm': valueCm,
    'taken_at': takenAt.millisecondsSinceEpoch,
    'note': note,
  };

  factory Measurement.fromMap(Map<String, dynamic> m) => Measurement(
    id: m['id'] as int?,
    part: BodyPart.values.firstWhere((b) => b.key == m['part']),
    valueCm: (m['value_cm'] as num).toDouble(),
    takenAt: DateTime.fromMillisecondsSinceEpoch(m['taken_at'] as int),
    note: m['note'] as String?,
  );
}

class WeightEntry {
  final int? id;
  final double kg;
  final DateTime takenAt;
  final String? note;

  WeightEntry({this.id, required this.kg, required this.takenAt, this.note});

  Map<String, dynamic> toMap() => {
    'id': id,
    'kg': kg,
    'taken_at': takenAt.millisecondsSinceEpoch,
    'note': note,
  };

  factory WeightEntry.fromMap(Map<String, dynamic> m) => WeightEntry(
    id: m['id'] as int?,
    kg: (m['kg'] as num).toDouble(),
    takenAt: DateTime.fromMillisecondsSinceEpoch(m['taken_at'] as int),
    note: m['note'] as String?,
  );
}

class InBodyScan {
  final int? id;
  final DateTime takenAt;
  final double? weightKg;
  final double? skeletalMuscleMassKg;
  final double? bodyFatMassKg;
  final double? bmi;
  final double? percentBodyFat;
  final double? bmrKcal;
  final double? inBodyScore;
  final double? rightArmLeanKg;
  final double? leftArmLeanKg;
  final double? trunkLeanKg;
  final double? rightLegLeanKg;
  final double? leftLegLeanKg;
  final double? rightArmFatKg;
  final double? leftArmFatKg;
  final double? trunkFatKg;
  final double? rightLegFatKg;
  final double? leftLegFatKg;
  final double? waistHipRatio;
  final double? visceralFatLevel;
  final double? totalBodyWaterL;
  final double? proteinKg;
  final double? mineralKg;
  final double? smiKgM2;

  InBodyScan({
    this.id,
    required this.takenAt,
    this.weightKg,
    this.skeletalMuscleMassKg,
    this.bodyFatMassKg,
    this.bmi,
    this.percentBodyFat,
    this.bmrKcal,
    this.inBodyScore,
    this.rightArmLeanKg,
    this.leftArmLeanKg,
    this.trunkLeanKg,
    this.rightLegLeanKg,
    this.leftLegLeanKg,
    this.rightArmFatKg,
    this.leftArmFatKg,
    this.trunkFatKg,
    this.rightLegFatKg,
    this.leftLegFatKg,
    this.waistHipRatio,
    this.visceralFatLevel,
    this.totalBodyWaterL,
    this.proteinKg,
    this.mineralKg,
    this.smiKgM2,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'taken_at': takenAt.millisecondsSinceEpoch,
    'weight_kg': weightKg,
    'smm_kg': skeletalMuscleMassKg,
    'bfm_kg': bodyFatMassKg,
    'bmi': bmi,
    'pbf': percentBodyFat,
    'bmr': bmrKcal,
    'inbody_score': inBodyScore,
    'r_arm_lean': rightArmLeanKg,
    'l_arm_lean': leftArmLeanKg,
    'trunk_lean': trunkLeanKg,
    'r_leg_lean': rightLegLeanKg,
    'l_leg_lean': leftLegLeanKg,
    'r_arm_fat': rightArmFatKg,
    'l_arm_fat': leftArmFatKg,
    'trunk_fat': trunkFatKg,
    'r_leg_fat': rightLegFatKg,
    'l_leg_fat': leftLegFatKg,
    'whr': waistHipRatio,
    'vfl': visceralFatLevel,
    'tbw_l': totalBodyWaterL,
    'protein_kg': proteinKg,
    'mineral_kg': mineralKg,
    'smi': smiKgM2,
  };

  factory InBodyScan.fromMap(Map<String, dynamic> m) => InBodyScan(
    id: m['id'] as int?,
    takenAt: DateTime.fromMillisecondsSinceEpoch(m['taken_at'] as int),
    weightKg: (m['weight_kg'] as num?)?.toDouble(),
    skeletalMuscleMassKg: (m['smm_kg'] as num?)?.toDouble(),
    bodyFatMassKg: (m['bfm_kg'] as num?)?.toDouble(),
    bmi: (m['bmi'] as num?)?.toDouble(),
    percentBodyFat: (m['pbf'] as num?)?.toDouble(),
    bmrKcal: (m['bmr'] as num?)?.toDouble(),
    inBodyScore: (m['inbody_score'] as num?)?.toDouble(),
    rightArmLeanKg: (m['r_arm_lean'] as num?)?.toDouble(),
    leftArmLeanKg: (m['l_arm_lean'] as num?)?.toDouble(),
    trunkLeanKg: (m['trunk_lean'] as num?)?.toDouble(),
    rightLegLeanKg: (m['r_leg_lean'] as num?)?.toDouble(),
    leftLegLeanKg: (m['l_leg_lean'] as num?)?.toDouble(),
    rightArmFatKg: (m['r_arm_fat'] as num?)?.toDouble(),
    leftArmFatKg: (m['l_arm_fat'] as num?)?.toDouble(),
    trunkFatKg: (m['trunk_fat'] as num?)?.toDouble(),
    rightLegFatKg: (m['r_leg_fat'] as num?)?.toDouble(),
    leftLegFatKg: (m['l_leg_fat'] as num?)?.toDouble(),
    waistHipRatio: (m['whr'] as num?)?.toDouble(),
    visceralFatLevel: (m['vfl'] as num?)?.toDouble(),
    totalBodyWaterL: (m['tbw_l'] as num?)?.toDouble(),
    proteinKg: (m['protein_kg'] as num?)?.toDouble(),
    mineralKg: (m['mineral_kg'] as num?)?.toDouble(),
    smiKgM2: (m['smi'] as num?)?.toDouble(),
  );
}

enum Sex { male, female, other }

class UserProfile {
  final String? name;
  final int? ageYears;
  final Sex? sex;
  final double? heightCm;
  final String goal;
  final double? targetWeightKg;
  final double? targetBodyFatPct;
  final String? targetDate; // ISO date or free text
  final String? activityLevel;
  final String? notes;

  const UserProfile({
    this.name,
    this.ageYears,
    this.sex,
    this.heightCm,
    this.goal = 'Lose body fat while preserving muscle',
    this.targetWeightKg,
    this.targetBodyFatPct,
    this.targetDate,
    this.activityLevel,
    this.notes,
  });

  UserProfile copyWith({
    String? name,
    int? ageYears,
    Sex? sex,
    double? heightCm,
    String? goal,
    double? targetWeightKg,
    double? targetBodyFatPct,
    String? targetDate,
    String? activityLevel,
    String? notes,
  }) {
    return UserProfile(
      name: name ?? this.name,
      ageYears: ageYears ?? this.ageYears,
      sex: sex ?? this.sex,
      heightCm: heightCm ?? this.heightCm,
      goal: goal ?? this.goal,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      targetBodyFatPct: targetBodyFatPct ?? this.targetBodyFatPct,
      targetDate: targetDate ?? this.targetDate,
      activityLevel: activityLevel ?? this.activityLevel,
      notes: notes ?? this.notes,
    );
  }
}
