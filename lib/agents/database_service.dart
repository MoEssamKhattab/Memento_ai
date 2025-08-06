import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// SQLite database service for long-term memory storage
class DatabaseService {
  static Database? _database;
  static const String _databaseName = 'agent_memory.db';
  static const String _eventsTable = 'events';

  /// Get the database instance (singleton)
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize the database
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createTables,
    );
  }

  /// Create database tables
  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_eventsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        start_time TEXT NOT NULL,
        end_time TEXT NOT NULL,
        location TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create indexes for better query performance
    await db.execute('''
      CREATE INDEX idx_events_start_time ON $_eventsTable (start_time)
    ''');
    
    await db.execute('''
      CREATE INDEX idx_events_title ON $_eventsTable (title)
    ''');
  }

  /// Execute a SELECT query and return results
  Future<List<Map<String, dynamic>>> executeQuery(String sqlQuery) async {
    final db = await database;
    
    try {
      // Validate that it's a SELECT query for security
      final trimmedQuery = sqlQuery.trim().toLowerCase();
      if (!trimmedQuery.startsWith('select')) {
        throw Exception('Only SELECT queries are allowed');
      }

      final results = await db.rawQuery(sqlQuery);
      return results;
    } catch (e) {
      throw Exception('Database query error: $e');
    }
  }

  /// Insert a new event
  Future<int> insertEvent(Map<String, dynamic> eventData) async {
    final db = await database;
    
    try {
      final id = await db.insert(_eventsTable, eventData);
      return id;
    } catch (e) {
      throw Exception('Failed to insert event: $e');
    }
  }

  /// Update an existing event
  Future<int> updateEvent(int eventId, Map<String, dynamic> updates) async {
    final db = await database;
    
    try {
      final rowsAffected = await db.update(
        _eventsTable,
        updates,
        where: 'id = ?',
        whereArgs: [eventId],
      );
      return rowsAffected;
    } catch (e) {
      throw Exception('Failed to update event: $e');
    }
  }

  /// Delete an event
  Future<int> deleteEvent(int eventId) async {
    final db = await database;
    
    try {
      final rowsAffected = await db.delete(
        _eventsTable,
        where: 'id = ?',
        whereArgs: [eventId],
      );
      return rowsAffected;
    } catch (e) {
      throw Exception('Failed to delete event: $e');
    }
  }

  /// Get event by ID
  Future<Map<String, dynamic>?> getEventById(int eventId) async {
    final db = await database;
    
    try {
      final results = await db.query(
        _eventsTable,
        where: 'id = ?',
        whereArgs: [eventId],
        limit: 1,
      );
      
      return results.isNotEmpty ? results.first : null;
    } catch (e) {
      throw Exception('Failed to get event: $e');
    }
  }

  /// Get all events (with optional limit)
  Future<List<Map<String, dynamic>>> getAllEvents({int? limit}) async {
    final db = await database;
    
    try {
      final results = await db.query(
        _eventsTable,
        orderBy: 'start_time ASC',
        limit: limit,
      );
      return results;
    } catch (e) {
      throw Exception('Failed to get events: $e');
    }
  }

  /// Search events by title (case-insensitive)
  Future<List<Map<String, dynamic>>> searchEventsByTitle(String searchTerm) async {
    final db = await database;
    
    try {
      final results = await db.query(
        _eventsTable,
        where: 'title LIKE ?',
        whereArgs: ['%$searchTerm%'],
        orderBy: 'start_time ASC',
      );
      return results;
    } catch (e) {
      throw Exception('Failed to search events: $e');
    }
  }

  /// Get events within a date range
  Future<List<Map<String, dynamic>>> getEventsInRange(
    DateTime startDate, 
    DateTime endDate
  ) async {
    final db = await database;
    
    try {
      final results = await db.query(
        _eventsTable,
        where: 'start_time >= ? AND start_time <= ?',
        whereArgs: [
          startDate.toIso8601String(),
          endDate.toIso8601String(),
        ],
        orderBy: 'start_time ASC',
      );
      return results;
    } catch (e) {
      throw Exception('Failed to get events in range: $e');
    }
  }

  /// Close the database connection
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  /// Clear all events (for testing/debugging)
  Future<void> clearAllEvents() async {
    final db = await database;
    await db.delete(_eventsTable);
  }

  /// Get database statistics
  Future<Map<String, dynamic>> getDatabaseStats() async {
    final db = await database;
    
    final countResult = await db.rawQuery('SELECT COUNT(*) as count FROM $_eventsTable');
    final totalEvents = countResult.first['count'] as int;
    
    final sizeResult = await db.rawQuery('PRAGMA page_count');
    final pageCount = sizeResult.first['page_count'] as int;
    
    return {
      'total_events': totalEvents,
      'database_pages': pageCount,
      'database_name': _databaseName,
      'table_name': _eventsTable,
    };
  }
}
