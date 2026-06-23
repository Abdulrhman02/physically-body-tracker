import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/models.dart';

class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'body_tracker.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, v) async {
        await db.execute('''
          CREATE TABLE measurements(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            part TEXT NOT NULL,
            value_cm REAL NOT NULL,
            taken_at INTEGER NOT NULL,
            note TEXT
          )
        ''');
        await db.execute('CREATE INDEX idx_meas_part ON measurements(part, taken_at)');

        await db.execute('''
          CREATE TABLE weights(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            kg REAL NOT NULL,
            taken_at INTEGER NOT NULL,
            note TEXT
          )
        ''');
        await db.execute('CREATE INDEX idx_weight_date ON weights(taken_at)');

        await db.execute('''
          CREATE TABLE inbody_scans(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            taken_at INTEGER NOT NULL UNIQUE,
            weight_kg REAL, smm_kg REAL, bfm_kg REAL, bmi REAL, pbf REAL,
            bmr REAL, inbody_score REAL,
            r_arm_lean REAL, l_arm_lean REAL, trunk_lean REAL,
            r_leg_lean REAL, l_leg_lean REAL,
            r_arm_fat REAL, l_arm_fat REAL, trunk_fat REAL,
            r_leg_fat REAL, l_leg_fat REAL,
            whr REAL, vfl REAL, tbw_l REAL, protein_kg REAL,
            mineral_kg REAL, smi REAL
          )
        ''');
      },
    );
    return _db!;
  }

  Future<int> insertMeasurement(Measurement m) async =>
      (await db).insert('measurements', m.toMap()..remove('id'));

  Future<List<Measurement>> measurementsFor(BodyPart part) async {
    final rows = await (await db).query(
      'measurements',
      where: 'part = ?',
      whereArgs: [part.key],
      orderBy: 'taken_at ASC',
    );
    return rows.map(Measurement.fromMap).toList();
  }

  Future<Map<BodyPart, List<Measurement>>> allMeasurementsByPart() async {
    final out = <BodyPart, List<Measurement>>{};
    for (final p in BodyPart.values) {
      out[p] = await measurementsFor(p);
    }
    return out;
  }

  Future<Map<BodyPart, Measurement?>> latestPerPart() async {
    final result = <BodyPart, Measurement?>{};
    for (final p in BodyPart.values) {
      final rows = await (await db).query(
        'measurements',
        where: 'part = ?',
        whereArgs: [p.key],
        orderBy: 'taken_at DESC',
        limit: 1,
      );
      result[p] = rows.isEmpty ? null : Measurement.fromMap(rows.first);
    }
    return result;
  }

  Future<int> deleteMeasurement(int id) async =>
      (await db).delete('measurements', where: 'id = ?', whereArgs: [id]);

  Future<int> insertWeight(WeightEntry w) async =>
      (await db).insert('weights', w.toMap()..remove('id'));

  Future<List<WeightEntry>> allWeights() async {
    final rows = await (await db).query('weights', orderBy: 'taken_at ASC');
    return rows.map(WeightEntry.fromMap).toList();
  }

  Future<int> deleteWeight(int id) async =>
      (await db).delete('weights', where: 'id = ?', whereArgs: [id]);

  Future<int> upsertInBody(InBodyScan s) async {
    return (await db).insert(
      'inbody_scans',
      s.toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<InBodyScan>> allInBody() async {
    final rows = await (await db).query('inbody_scans', orderBy: 'taken_at ASC');
    return rows.map(InBodyScan.fromMap).toList();
  }

  Future<InBodyScan?> latestInBody() async {
    final rows = await (await db)
        .query('inbody_scans', orderBy: 'taken_at DESC', limit: 1);
    return rows.isEmpty ? null : InBodyScan.fromMap(rows.first);
  }

  Future<int> deleteInBody(int id) async =>
      (await db).delete('inbody_scans', where: 'id = ?', whereArgs: [id]);

  Future<void> wipeAll() async {
    final database = await db;
    await database.delete('measurements');
    await database.delete('weights');
    await database.delete('inbody_scans');
  }
}
