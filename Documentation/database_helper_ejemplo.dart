import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Helper class to manage the SQLite database.
class DatabaseHelper {
  DatabaseHelper._internal();

  static const _databaseVersion = 6;
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  /// Singleton instance of [DatabaseHelper].
  static DatabaseHelper get instance => _instance;

  static Database? _database;

  /// Retrieves the database instance, initializing it if necessary.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('froghappy.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
      onConfigure: (db) async {
        // Enable foreign key constraints
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Habits Table
    await db.execute(
      '''
CREATE TABLE habits(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT,
  created_at TEXT
)''',
    );

    // Habit Completions Table
    await db.execute(
      '''
CREATE TABLE habit_completions(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  habit_id INTEGER,
  date TEXT,
  FOREIGN KEY(habit_id) REFERENCES habits(id) ON DELETE CASCADE
)''',
    );

    // Goals Table
    await db.execute(
      '''
CREATE TABLE goals(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  is_completed INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL,
  completed_at TEXT,
  priority INTEGER NOT NULL DEFAULT 1,
  due_date TEXT,
  description TEXT
)''',
    );

    // Comments Table
    await db.execute(
      '''
CREATE TABLE comments(
  id TEXT PRIMARY KEY,
  goal_id INTEGER NOT NULL,
  content TEXT NOT NULL,
  created_at TEXT NOT NULL,
  FOREIGN KEY(goal_id) REFERENCES goals(id) ON DELETE CASCADE
)''',
    );

    // Daily Tasks Table
    await db.execute(
      '''
CREATE TABLE tasks_daily(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  created_at TEXT NOT NULL,
  assigned_date TEXT NOT NULL,
  is_completed INTEGER NOT NULL DEFAULT 0,
  completed_at TEXT,
  is_cancelled INTEGER NOT NULL DEFAULT 0,
  cancelled_at TEXT,
  move_count INTEGER NOT NULL DEFAULT 0
)''',
    );

    // Task Comments Table
    await db.execute(
      '''
CREATE TABLE task_comments(
  id TEXT PRIMARY KEY,
  task_id INTEGER NOT NULL,
  content TEXT NOT NULL,
  created_at TEXT NOT NULL,
  FOREIGN KEY(task_id) REFERENCES tasks_daily(id) ON DELETE CASCADE
)''',
    );

    // Daily Reflections Table
    await db.execute(
      '''
CREATE TABLE daily_reflections(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  date TEXT NOT NULL,
  emoji TEXT,
  reflection TEXT,
  created_at TEXT NOT NULL
)''',
    );
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Daily Tasks Table
      await db.execute(
        '''
CREATE TABLE tasks_daily(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  created_at TEXT NOT NULL,
  assigned_date TEXT NOT NULL,
  is_completed INTEGER NOT NULL DEFAULT 0,
  completed_at TEXT,
  is_cancelled INTEGER NOT NULL DEFAULT 0,
  cancelled_at TEXT,
  move_count INTEGER NOT NULL DEFAULT 0
)''',
      );

      // Task Comments Table
      await db.execute(
        '''
CREATE TABLE task_comments(
  id TEXT PRIMARY KEY,
  task_id INTEGER NOT NULL,
  content TEXT NOT NULL,
  created_at TEXT NOT NULL,
  FOREIGN KEY(task_id) REFERENCES tasks_daily(id) ON DELETE CASCADE
)''',
      );
    }

    if (oldVersion < 3) {
      // Add new columns to goals table
      await db.execute(
        'ALTER TABLE goals ADD COLUMN priority INTEGER NOT NULL DEFAULT 1',
      );
      await db.execute('ALTER TABLE goals ADD COLUMN due_date TEXT');
      await db.execute('ALTER TABLE goals ADD COLUMN description TEXT');
    }

    if (oldVersion < 4) {
      // Version 4: No schema changes, but ensures foreign keys are enabled
      // via onConfigure callback. This allows ON DELETE CASCADE to work.
    }

    if (oldVersion < 5) {
      // Daily Reflections Table
      await db.execute(
        '''
CREATE TABLE daily_reflections(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  date TEXT NOT NULL UNIQUE,
  emoji TEXT,
  reflection TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT
)''',
      );
    }

    if (oldVersion < 6) {
      // Allow multiple reflections per day (remove UNIQUE constraint on date)
      await db.transaction((txn) async {
        await txn.execute(
          'ALTER TABLE daily_reflections RENAME TO daily_reflections_old',
        );
        await txn.execute('''
          CREATE TABLE daily_reflections(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL,
            emoji TEXT,
            reflection TEXT,
            created_at TEXT NOT NULL
          )
        ''');
        await txn.execute('''
          INSERT INTO daily_reflections (id, date, emoji, reflection, created_at)
          SELECT id, date, emoji, reflection, created_at FROM daily_reflections_old
        ''');
        await txn.execute('DROP TABLE daily_reflections_old');
      });
    }
  }

  /// Closes the database connection.
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
