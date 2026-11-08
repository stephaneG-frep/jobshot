import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/models.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._();
  factory DatabaseHelper() => instance;
  DatabaseHelper._();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'jobshot.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE applications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entreprise TEXT NOT NULL,
        poste TEXT NOT NULL,
        statut TEXT NOT NULL DEFAULT 'aPreparer',
        dateCandidature TEXT NOT NULL,
        source TEXT NOT NULL DEFAULT 'autre',
        url TEXT,
        localisation TEXT,
        recruteur TEXT,
        email TEXT,
        telephone TEXT,
        referenceOffre TEXT,
        notes TEXT,
        prochainesActions TEXT,
        dateRelance TEXT,
        dateEntretien TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE captures (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        applicationId INTEGER NOT NULL,
        imagePath TEXT NOT NULL,
        ocrText TEXT,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (applicationId) REFERENCES applications(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE status_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        applicationId INTEGER NOT NULL,
        oldStatus TEXT NOT NULL,
        newStatus TEXT NOT NULL,
        note TEXT,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (applicationId) REFERENCES applications(id) ON DELETE CASCADE
      )
    ''');
  }

  // --- Applications ---

  Future<int> insertApplication(Application app) async {
    final db = await database;
    final map = app.toMap();
    map.remove('id');
    return await db.insert('applications', map);
  }

  Future<int> updateApplication(Application app) async {
    final db = await database;
    final map = app.toMap();
    map['updatedAt'] = DateTime.now().toIso8601String();
    return await db.update(
      'applications',
      map,
      where: 'id = ?',
      whereArgs: [app.id],
    );
  }

  Future<int> deleteApplication(int id) async {
    final db = await database;
    return await db.delete('applications', where: 'id = ?', whereArgs: [id]);
  }

  Future<Application?> getApplication(int id) async {
    final db = await database;
    final maps = await db.query('applications', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Application.fromMap(maps.first);
  }

  Future<List<Application>> getAllApplications() async {
    final db = await database;
    final maps = await db.query('applications', orderBy: 'updatedAt DESC');
    return maps.map((m) => Application.fromMap(m)).toList();
  }

  Future<List<Application>> searchApplications(String query) async {
    final db = await database;
    final q = '%$query%';
    final maps = await db.query(
      'applications',
      where:
          'entreprise LIKE ? OR poste LIKE ? OR recruteur LIKE ? OR email LIKE ? OR notes LIKE ?',
      whereArgs: [q, q, q, q, q],
      orderBy: 'updatedAt DESC',
    );
    return maps.map((m) => Application.fromMap(m)).toList();
  }

  Future<List<Application>> filterByStatus(AppStatus status) async {
    final db = await database;
    final maps = await db.query(
      'applications',
      where: 'statut = ?',
      whereArgs: [status.name],
      orderBy: 'updatedAt DESC',
    );
    return maps.map((m) => Application.fromMap(m)).toList();
  }

  Future<List<Application>> getApplicationsNeedingRelance() async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final maps = await db.query(
      'applications',
      where: 'dateRelance IS NOT NULL AND dateRelance <= ?',
      whereArgs: [now],
      orderBy: 'dateRelance ASC',
    );
    return maps.map((m) => Application.fromMap(m)).toList();
  }

  Future<List<Application>> getUpcomingEntretiens() async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final maps = await db.query(
      'applications',
      where: 'dateEntretien IS NOT NULL AND dateEntretien >= ?',
      whereArgs: [now],
      orderBy: 'dateEntretien ASC',
    );
    return maps.map((m) => Application.fromMap(m)).toList();
  }

  Future<int> getStatusCount(AppStatus status) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM applications WHERE statut = ?',
      [status.name],
    );
    return result.first['count'] as int;
  }

  Future<int> getTotalCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM applications');
    return result.first['count'] as int;
  }

  // --- Captures ---

  Future<int> insertCapture(Capture capture) async {
    final db = await database;
    final map = capture.toMap();
    map.remove('id');
    return await db.insert('captures', map);
  }

  Future<int> updateCaptureOcr(int captureId, String ocrText) async {
    final db = await database;
    return await db.update(
      'captures',
      {'ocrText': ocrText},
      where: 'id = ?',
      whereArgs: [captureId],
    );
  }

  Future<List<Capture>> getCapturesForApplication(int applicationId) async {
    final db = await database;
    final maps = await db.query(
      'captures',
      where: 'applicationId = ?',
      whereArgs: [applicationId],
      orderBy: 'createdAt ASC',
    );
    return maps.map((m) => Capture.fromMap(m)).toList();
  }

  Future<int> deleteCapture(int id) async {
    final db = await database;
    return await db.delete('captures', where: 'id = ?', whereArgs: [id]);
  }

  // --- Status History ---

  Future<int> insertStatusHistory(StatusHistory history) async {
    final db = await database;
    final map = history.toMap();
    map.remove('id');
    return await db.insert('status_history', map);
  }

  Future<List<StatusHistory>> getHistoryForApplication(int applicationId) async {
    final db = await database;
    final maps = await db.query(
      'status_history',
      where: 'applicationId = ?',
      whereArgs: [applicationId],
      orderBy: 'createdAt DESC',
    );
    return maps.map((m) => StatusHistory.fromMap(m)).toList();
  }

  // --- Export / Import ---

  Future<Map<String, dynamic>> exportAll() async {
    final db = await database;
    final apps = await db.query('applications');
    final captures = await db.query('captures');
    final history = await db.query('status_history');
    return {
      'applications': apps,
      'captures': captures,
      'status_history': history,
      'exportDate': DateTime.now().toIso8601String(),
      'version': 1,
    };
  }

  Future<void> importAll(Map<String, dynamic> data) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('applications');
      await txn.delete('captures');
      await txn.delete('status_history');

      for (final app in (data['applications'] as List)) {
        await txn.insert('applications', Map<String, dynamic>.from(app));
      }
      for (final cap in (data['captures'] as List)) {
        await txn.insert('captures', Map<String, dynamic>.from(cap));
      }
      for (final hist in (data['status_history'] as List)) {
        await txn.insert('status_history', Map<String, dynamic>.from(hist));
      }
    });
  }
}
