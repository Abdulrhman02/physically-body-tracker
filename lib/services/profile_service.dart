import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class ProfileService {
  ProfileService._();
  static final ProfileService instance = ProfileService._();

  static const _kName = 'profile.name';
  static const _kAge = 'profile.age';
  static const _kSex = 'profile.sex';
  static const _kHeight = 'profile.height_cm';
  static const _kGoal = 'profile.goal';
  static const _kTargetWeight = 'profile.target_weight';
  static const _kTargetBf = 'profile.target_bf';
  static const _kTargetDate = 'profile.target_date';
  static const _kActivity = 'profile.activity';
  static const _kNotes = 'profile.notes';

  Future<UserProfile> load() async {
    final p = await SharedPreferences.getInstance();
    Sex? sex;
    final s = p.getString(_kSex);
    if (s != null) {
      sex = Sex.values.firstWhere((e) => e.name == s, orElse: () => Sex.other);
    }
    return UserProfile(
      name: p.getString(_kName),
      ageYears: p.getInt(_kAge),
      sex: sex,
      heightCm: p.getDouble(_kHeight),
      goal: p.getString(_kGoal) ?? 'Lose body fat while preserving muscle',
      targetWeightKg: p.getDouble(_kTargetWeight),
      targetBodyFatPct: p.getDouble(_kTargetBf),
      targetDate: p.getString(_kTargetDate),
      activityLevel: p.getString(_kActivity),
      notes: p.getString(_kNotes),
    );
  }

  Future<void> save(UserProfile profile) async {
    final p = await SharedPreferences.getInstance();
    Future<void> setOrRemove(String k, Object? v) async {
      if (v == null || (v is String && v.isEmpty)) {
        await p.remove(k);
      } else if (v is String) {
        await p.setString(k, v);
      } else if (v is int) {
        await p.setInt(k, v);
      } else if (v is double) {
        await p.setDouble(k, v);
      }
    }

    await setOrRemove(_kName, profile.name);
    await setOrRemove(_kAge, profile.ageYears);
    await setOrRemove(_kSex, profile.sex?.name);
    await setOrRemove(_kHeight, profile.heightCm);
    await setOrRemove(_kGoal, profile.goal);
    await setOrRemove(_kTargetWeight, profile.targetWeightKg);
    await setOrRemove(_kTargetBf, profile.targetBodyFatPct);
    await setOrRemove(_kTargetDate, profile.targetDate);
    await setOrRemove(_kActivity, profile.activityLevel);
    await setOrRemove(_kNotes, profile.notes);
  }
}
