import 'package:sqflite/sqflite.dart';
import '../models/account.dart';
import 'package:nudge/models/task.dart';

class DatabaseService {
  static final DatabaseService _databaseService = DatabaseService._internal();
  factory DatabaseService() => _databaseService;
  DatabaseService._internal();
  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = '$databasePath/nudge_app.db';
    final database = await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async => await db.execute('PRAGMA foreign_keys = ON'),
    );
    _database = database;
    return database;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute(
      "CREATE TABLE account (uuid TEXT PRIMARY KEY, api_id TEXT, user_level INTEGER DEFAULT 0, api_name TEXT, api_email TEXT, api_photo_url TEXT, is_signed_in INTEGER DEFAULT 0, is_public INTEGER DEFAULT 0, is_contributor_mode INTEGER DEFAULT 0, is_restricted INTEGER DEFAULT 0, is_synchronized INTEGER DEFAULT 0, ttl TEXT, created_at TEXT NOT NULL);",
    );
    await db.execute('DROP TABLE IF EXISTS tasks');
    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        "column" TEXT NOT NULL,
        startDate TEXT,
        endDate TEXT
      );
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await db.execute('ALTER TABLE tasks ADD COLUMN startDate TEXT;');
    await db.execute('ALTER TABLE tasks ADD COLUMN endDate TEXT;');
  }
  // helper methods
  Future<void> insertAccount(Account account) async {
    final db = await _databaseService.database;
    await db.insert(
      'account',
      account.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateAccount(Account account) async {
    final db = await _databaseService.database;
    await db.update('account', account.toMap(),
        where: 'uuid = ?', whereArgs: [account.uuid]);
  }

  Future<List<Account>> getAccount(uuid) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps =
        await db.query('account', where: 'uuid = ?', whereArgs: [uuid]);
    return List.generate(maps.length, (index) => Account.fromMap(maps[index]));
  }

  Future<List<Account>> getSignedAccount() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'account',
      where: 'is_signed_in = 1',
      orderBy: 'created_at DESC',
      limit: 1,
    );
    return List.generate(maps.length, (index) => Account.fromMap(maps[index]));
  }

  Future<List<Account>> getAccounts(int limit) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps =
        await db.query('account', limit: limit);
    return List.generate(maps.length, (index) => Account.fromMap(maps[index]));
  }

  Future<void> clearAccounts() async {
    final db = await _databaseService.database;
    await db.delete('account');
  }

  // Task methods
  // Add a new task
  Future<void> insertTask(Task task) async {
    final db = await database;
    await db.insert('tasks', task.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Get all tasks
  Future<List<Task>> getTasks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('tasks');
    return List.generate(maps.length, (i) => Task.fromMap(maps[i]));
  }

  // Update a task's column (for drag-and-drop)
  Future<void> updateTaskColumn(int id, String newColumn) async {
    final db = await database;
    await db.update('tasks', {'column': newColumn},
        where: 'id = ?', whereArgs: [id]);
  }
}
