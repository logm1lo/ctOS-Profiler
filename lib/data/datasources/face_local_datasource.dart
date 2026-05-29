import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/face_record.dart';


class FaceLocalDataSource {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'ctos_faces.db');
    return await openDatabase(
      path,
      version: 6,
      onCreate: (db, version) {
        return db.execute(
          '''
          CREATE TABLE registered_faces(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            embedding TEXT,
            model_used TEXT,
            photo_path TEXT,
            photo_bytes BLOB,
            timestamp INTEGER,
            age INTEGER,
            occupation TEXT,
            income_level TEXT,
            risk_score INTEGER,
            personality_traits TEXT,
            birth_date TEXT,
            height REAL,
            weight REAL
          )
          ''',
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE registered_faces ADD COLUMN age INTEGER');
          await db.execute('ALTER TABLE registered_faces ADD COLUMN occupation TEXT');
          await db.execute('ALTER TABLE registered_faces ADD COLUMN income_level TEXT');
          await db.execute('ALTER TABLE registered_faces ADD COLUMN risk_score INTEGER');
          await db.execute('ALTER TABLE registered_faces ADD COLUMN personality_traits TEXT');
        }
        if (oldVersion < 3) {
           await _addColumnIfNotExists(db, 'registered_faces', 'age', 'INTEGER');
           await _addColumnIfNotExists(db, 'registered_faces', 'occupation', 'TEXT');
           await _addColumnIfNotExists(db, 'registered_faces', 'income_level', 'TEXT');
           await _addColumnIfNotExists(db, 'registered_faces', 'risk_score', 'INTEGER');
           await _addColumnIfNotExists(db, 'registered_faces', 'personality_traits', 'TEXT');
        }
        if (oldVersion < 4) {
          await _addColumnIfNotExists(db, 'registered_faces', 'birth_date', 'TEXT');
          await _addColumnIfNotExists(db, 'registered_faces', 'height', 'REAL');
          await _addColumnIfNotExists(db, 'registered_faces', 'weight', 'REAL');
        }
        if (oldVersion < 5) {
          await _addColumnIfNotExists(db, 'registered_faces', 'photo_bytes', 'BLOB');
        }
        if (oldVersion < 6) {
          // No structural change, but we might want to ensure 'embedding' format is handled.
          // The current code already handles both old (List<double>) and new (List<List<double>>) JSON formats in FaceRecord.fromMap
        }
      },
    );
  }

  Future<void> _addColumnIfNotExists(Database db, String table, String column, String type) async {
    var columns = await db.rawQuery('PRAGMA table_info($table)');
    if (columns.any((c) => c['name'] == column)) return;
    await db.execute('ALTER TABLE $table ADD COLUMN $column $type');
  }

  Future<void> insertFace(FaceRecord face) async {
    final db = await database;
    await db.insert(
      'registered_faces',
      face.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<FaceRecord>> getAllFaces() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('registered_faces');
    return List.generate(maps.length, (i) {
      return FaceRecord.fromMap(maps[i]);
    });
  }

  Future<void> updateFace(FaceRecord face) async {
    final db = await database;
    await db.update(
      'registered_faces',
      face.toMap(),
      where: 'id = ?',
      whereArgs: [face.id],
    );
  }

  Future<String> getDatabasePath() async {
    return join(await getDatabasesPath(), 'ctos_faces.db');
  }

  Future<void> exportDatabaseToPath(String path) async {
    // 1. Flush any pending changes to the WAL file
    final db = await database;
    try {
      await db.execute('PRAGMA wal_checkpoint(FULL);');
    } catch (e) {
      // Ignore if PRAGMA fails, proceed with close/copy
    }

    // 2. Close the database to release all file locks and merge WAL
    if (_database != null) {
      await _database!.close();
      _database = null;
    }

    try {
      final dbPath = await getDatabasePath();
      final sourceFile = File(dbPath);

      if (await sourceFile.exists()) {
        // 3. Perform the copy while the DB is closed
        await sourceFile.copy(path);
      } else {
        throw Exception("Source database file not found at $dbPath");
      }
    } finally {
      // 4. Re-open the database so the application can continue using it
      _database = await _initDatabase();
    }
  }

  Future<String> exportDatabase() async {
    final directory = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
    final backupPath = join(directory.path, 'ctos_faces_backup_${DateTime.now().millisecondsSinceEpoch}.db');
    await exportDatabaseToPath(backupPath);
    return backupPath;
  }

  Future<void> importDatabase(String path) async {
    final dbPath = join(await getDatabasesPath(), 'ctos_faces.db');
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
    // Delete the database and auxiliary files (-wal, -shm) before copying
    await deleteDatabase(dbPath);
    await File(path).copy(dbPath);
    // Re-open to ensure the new data is loaded
    _database = await _initDatabase();
  }

  Future<void> deleteFace(int id) async {


    final db = await database;
    await db.delete(
      'registered_faces',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
