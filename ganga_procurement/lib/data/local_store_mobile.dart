import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models.dart';
import 'local_store.dart';

LocalStore createLocalStore() => _SqliteLocalStore();

class _SqliteLocalStore implements LocalStore {
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    final directory = await getApplicationDocumentsDirectory();
    _database = await openDatabase(
      path.join(directory.path, 'ganga_procurement.db'),
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE farmers (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            mobile TEXT NOT NULL UNIQUE,
            village TEXT NOT NULL DEFAULT ''
          )
        ''');
        await db.execute('''
          CREATE TABLE weighments (
            id TEXT PRIMARY KEY,
            farmerId TEXT NOT NULL,
            farmerName TEXT NOT NULL,
            farmerMobile TEXT NOT NULL,
            crop TEXT NOT NULL,
            bagWeights TEXT NOT NULL,
            grossWeightKg REAL NOT NULL,
            bagCount INTEGER NOT NULL DEFAULT 0,
            weightEntryMode TEXT NOT NULL DEFAULT 'individual',
            gunnyPerBagKg REAL NOT NULL DEFAULT 0,
            kadthaKg REAL NOT NULL DEFAULT 0,
            ratePerQuintal REAL NOT NULL DEFAULT 0,
            interestRatePercent REAL NOT NULL DEFAULT 0,
            receiptType TEXT NOT NULL DEFAULT '',
            receiptPerBag REAL NOT NULL DEFAULT 0,
            createdAt TEXT NOT NULL,
            approvedByRole TEXT NOT NULL DEFAULT 'worker',
            slipPhotoBase64 TEXT,
            synced INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute(
          'CREATE INDEX weighments_createdAt ON weighments(createdAt)',
        );
        await db.execute(
          'CREATE INDEX weighments_farmerMobile ON weighments(farmerMobile)',
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            "ALTER TABLE weighments ADD COLUMN approvedByRole TEXT NOT NULL DEFAULT 'worker'",
          );
        }
        if (oldVersion < 3) {
          await db.execute(
            'ALTER TABLE weighments ADD COLUMN bagCount INTEGER NOT NULL DEFAULT 0',
          );
          await db.execute(
            "ALTER TABLE weighments ADD COLUMN weightEntryMode TEXT NOT NULL DEFAULT 'individual'",
          );
          await db.execute(
            'ALTER TABLE weighments ADD COLUMN gunnyPerBagKg REAL NOT NULL DEFAULT 0',
          );
          await db.execute(
            'ALTER TABLE weighments ADD COLUMN kadthaKg REAL NOT NULL DEFAULT 0',
          );
          await db.execute(
            'ALTER TABLE weighments ADD COLUMN ratePerQuintal REAL NOT NULL DEFAULT 0',
          );
          await db.execute(
            'ALTER TABLE weighments ADD COLUMN interestRatePercent REAL NOT NULL DEFAULT 0',
          );
          await db.execute(
            "ALTER TABLE weighments ADD COLUMN receiptType TEXT NOT NULL DEFAULT ''",
          );
          await db.execute(
            'ALTER TABLE weighments ADD COLUMN receiptPerBag REAL NOT NULL DEFAULT 0',
          );
        }
      },
    );
    return _database!;
  }

  @override
  Future<List<Farmer>> farmers() async {
    final rows = await (await database).query('farmers', orderBy: 'name COLLATE NOCASE');
    return rows.map(Farmer.fromMap).toList();
  }

  @override
  Future<void> saveFarmer(Farmer farmer) async {
    await (await database).insert(
      'farmers',
      farmer.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<Weighment>> weighments() async {
    final rows = await (await database).query('weighments', orderBy: 'createdAt DESC');
    return rows.map(Weighment.fromMap).toList();
  }

  @override
  Future<void> saveWeighment(Weighment weighment) async {
    await (await database).insert(
      'weighments',
      weighment.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }
}
