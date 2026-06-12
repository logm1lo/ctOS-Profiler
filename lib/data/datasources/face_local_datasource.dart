import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/face_record.dart';


class FaceLocalDataSource {
  static const String TAG = "FaceLocalDataSource";
  static Database? _database;

  Future<Database> get database async {
    developer.log('[database] → Entry', name: TAG);
    if (_database != null && _database!.isOpen) {
      developer.log('[database] → Exit: Returning existing database instance', name: TAG);
      return _database!;
    }
    developer.log('[database] → Status: Initializing new database instance', name: TAG);
    _database = await _initDatabase();
    developer.log('[database] → Exit: Database initialized', name: TAG);
    return _database!;
  }

  Future<Database> _initDatabase() async {
    developer.log('[_initDatabase] → Entry', name: TAG);
    final dbPath = join(await getDatabasesPath(), 'ctos_faces.db');
    developer.log('[_initDatabase] → Path: $dbPath', name: TAG);

    return await openDatabase(
      dbPath,
      version: 11,
      onCreate: (db, version) {
        developer.log('[_initDatabase.onCreate] → Creating schema version $version', name: TAG);
        db.execute(
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
            weight REAL,
            hobby TEXT,
            secret TEXT,
            recent_history TEXT,
            social_links TEXT,
            aliases TEXT,
            digital_footprint_summary TEXT,
            is_poi INTEGER DEFAULT 0
          )
          ''',
        );
        return db.execute(
          '''
          CREATE TABLE poi_alerts(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            face_id INTEGER,
            timestamp INTEGER,
            latitude REAL,
            longitude REAL,
            media_path TEXT,
            FOREIGN KEY(face_id) REFERENCES registered_faces(id) ON DELETE CASCADE
          )
          ''',
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        developer.log('[_initDatabase.onUpgrade] → Migrating schema: $oldVersion to $newVersion', name: TAG);
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
        if (oldVersion < 8) {
          await _addColumnIfNotExists(db, 'registered_faces', 'social_links', 'TEXT');
          await _addColumnIfNotExists(db, 'registered_faces', 'aliases', 'TEXT');
          await _addColumnIfNotExists(db, 'registered_faces', 'digital_footprint_summary', 'TEXT');
        }
        if (oldVersion < 9) {
          await _addColumnIfNotExists(db, 'registered_faces', 'hobby', 'TEXT');
          await _addColumnIfNotExists(db, 'registered_faces', 'secret', 'TEXT');
          await _addColumnIfNotExists(db, 'registered_faces', 'recent_history', 'TEXT');
        }
        if (oldVersion < 10) {
          await _addColumnIfNotExists(db, 'registered_faces', 'is_poi', 'INTEGER DEFAULT 0');
        }
        if (oldVersion < 11) {
          await db.execute(
            '''
            CREATE TABLE poi_alerts(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              face_id INTEGER,
              timestamp INTEGER,
              latitude REAL,
              longitude REAL,
              media_path TEXT,
              FOREIGN KEY(face_id) REFERENCES registered_faces(id) ON DELETE CASCADE
            )
            ''',
          );
        }
      },
    );
  }

  Future<void> _addColumnIfNotExists(Database db, String table, String column, String type) async {
    developer.log('[_addColumnIfNotExists] → Entry: table=$table, column=$column', name: TAG);
    var columns = await db.rawQuery('PRAGMA table_info($table)');
    if (columns.any((c) => c['name'] == column)) {
      developer.log('[_addColumnIfNotExists] → Exit: Column already exists', name: TAG);
      return;
    }
    await db.execute('ALTER TABLE $table ADD COLUMN $column $type');
    developer.log('[_addColumnIfNotExists] → Exit: Column added', name: TAG);
  }

  Future<void> insertFace(FaceRecord face) async {
    developer.log('[insertFace] → Entry: faceName=${face.name}', name: TAG);
    final db = await database;
    try {
      final id = await db.insert(
        'registered_faces',
        face.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      developer.log('[insertFace] → Exit: Inserted with ID=$id', name: TAG);
    } catch (e) {
      developer.log('[insertFace] → Error: $e', name: TAG, error: e);
      rethrow;
    }
  }

  Future<List<FaceRecord>> getAllFaces() async {
    developer.log('[getAllFaces] → Entry', name: TAG);
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query('registered_faces');
      final result = List.generate(maps.length, (i) {
        return FaceRecord.fromMap(maps[i]);
      });
      developer.log('[getAllFaces] → Exit: Retrieved ${result.length} faces', name: TAG);
      return result;
    } catch (e) {
      developer.log('[getAllFaces] → Error: $e', name: TAG, error: e);
      return [];
    }
  }

  Future<void> updateFace(FaceRecord face) async {
    developer.log('[updateFace] → Entry: id=${face.id}, name=${face.name}', name: TAG);
    final db = await database;
    try {
      final count = await db.update(
        'registered_faces',
        face.toMap(),
        where: 'id = ?',
        whereArgs: [face.id],
      );
      developer.log('[updateFace] → Exit: Updated $count rows', name: TAG);
    } catch (e) {
      developer.log('[updateFace] → Error: $e', name: TAG, error: e);
    }
  }

  Future<String> getDatabasePath() async {
    return join(await getDatabasesPath(), 'ctos_faces.db');
  }

  Future<void> exportDatabaseToPath(String path) async {
    developer.log('[exportDatabaseToPath] → Entry: path=$path', name: TAG);
    final db = await database;
    try {
      developer.log('[exportDatabaseToPath] → Status: Checkpointing WAL', name: TAG);
      await db.execute('PRAGMA wal_checkpoint(FULL);');
    } catch (e) {
      developer.log('[exportDatabaseToPath] → Warning: WAL checkpoint failed: $e', name: TAG);
    }

    if (_database != null) {
      developer.log('[exportDatabaseToPath] → Status: Closing database before copy', name: TAG);
      await _database!.close();
      _database = null;
    }

    try {
      final dbPath = await getDatabasePath();
      final sourceFile = File(dbPath);

      if (await sourceFile.exists()) {
        await sourceFile.copy(path);
        developer.log('[exportDatabaseToPath] → Exit: Database copied to $path', name: TAG);
      } else {
        developer.log('[exportDatabaseToPath] → Error: Source database not found', name: TAG);
        throw Exception("Source database file not found at $dbPath");
      }
    } finally {
      _database = await _initDatabase();
    }
  }

  Future<String> exportDatabase() async {
    developer.log('[exportDatabase] → Entry', name: TAG);
    final directory = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
    final backupPath = join(directory.path, 'ctos_faces_backup_${DateTime.now().millisecondsSinceEpoch}.db');
    await exportDatabaseToPath(backupPath);
    developer.log('[exportDatabase] → Exit: Backup created at $backupPath', name: TAG);
    return backupPath;
  }

  Future<void> importDatabase(String path) async {
    developer.log('[importDatabase] → Entry: path=$path', name: TAG);
    final dbPath = join(await getDatabasesPath(), 'ctos_faces.db');
    if (_database != null) {
      developer.log('[importDatabase] → Status: Closing current database', name: TAG);
      await _database!.close();
      _database = null;
    }
    try {
      await deleteDatabase(dbPath);
      await File(path).copy(dbPath);
      _database = await _initDatabase();
      developer.log('[importDatabase] → Exit: Database imported successfully', name: TAG);
    } catch (e) {
      developer.log('[importDatabase] → Error: $e', name: TAG, error: e);
    }
  }

  Future<void> deleteFace(int id) async {
    developer.log('[deleteFace] → Entry: id=$id', name: TAG);
    final db = await database;
    try {
      final count = await db.delete(
        'registered_faces',
        where: 'id = ?',
        whereArgs: [id],
      );
      developer.log('[deleteFace] → Exit: Deleted $count rows', name: TAG);
    } catch (e) {
      developer.log('[deleteFace] → Error: $e', name: TAG, error: e);
    }
  }

  Future<void> insertPoiAlert(int faceId, double lat, double lon, String? mediaPath) async {
    developer.log('[insertPoiAlert] → Entry: faceId=$faceId, coords=($lat, $lon)', name: TAG);
    final db = await database;
    try {
      await db.insert('poi_alerts', {
        'face_id': faceId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'latitude': lat,
        'longitude': lon,
        'media_path': mediaPath,
      });
      developer.log('[insertPoiAlert] → Exit: Alert logged', name: TAG);
    } catch (e) {
      developer.log('[insertPoiAlert] → Error: $e', name: TAG, error: e);
    }
  }

  Future<List<Map<String, dynamic>>> getPoiAlerts(int faceId) async {
    developer.log('[getPoiAlerts] → Entry: faceId=$faceId', name: TAG);
    final db = await database;
    try {
      final alerts = await db.query(
        'poi_alerts',
        where: 'face_id = ?',
        whereArgs: [faceId],
        orderBy: 'timestamp DESC',
      );
      developer.log('[getPoiAlerts] → Exit: Retrieved ${alerts.length} alerts', name: TAG);
      return alerts;
    } catch (e) {
      developer.log('[getPoiAlerts] → Error: $e', name: TAG, error: e);
      return [];
    }
  }
}
