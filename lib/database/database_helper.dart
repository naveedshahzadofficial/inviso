import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Database? _database;
  
  static Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }
  
  static Future<Database> _initDatabase() async {
    // Initialize FFI for desktop platforms
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    
    String path = join(await getDatabasesPath(), 'screenshots.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }
  
  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
    CREATE TABLE screenshots (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    path TEXT NOT NULL,
    sub_type INTEGER,
    type_int INTEGER,
    duration INTEGER,
    latitude REAL,
    longitude REAL,
    text_content TEXT,
    width INTEGER,
    height INTEGER,
    orientation INTEGER DEFAULT 0,
    is_favorite INTEGER DEFAULT 0,
    relative_path TEXT,
    mime_type TEXT,
    created_date INTEGER,
    modified_date INTEGER
    )
    ''');
    
    // Create index for faster text search
    await db.execute('''
      CREATE INDEX idx_text_content ON screenshots(text_content)
    ''');
    
    // Create tags table
    await db.execute('''
      CREATE TABLE image_tags (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        image_id TEXT NOT NULL,
        tag_name TEXT NOT NULL,
        created_date INTEGER,
        FOREIGN KEY (image_id) REFERENCES screenshots (id),
        UNIQUE(image_id, tag_name)
      )
    ''');
  }
  
  static Future<void> insertScreenshot(Map<String, dynamic> screenshot) async {
    final db = await database;
    await db.insert('screenshots', screenshot, conflictAlgorithm: ConflictAlgorithm.replace);
  }
  
  static Future<List<Map<String, dynamic>>> searchScreenshots(String query, {int limit = 20, int offset = 0}) async {
    final db = await database;
    return await db.query(
      'screenshots',
      where: 'text_content LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'created_date DESC',
      limit: limit,
      offset: offset,
    );
  }
  
  static Future<List<Map<String, dynamic>>> getAllScreenshots({int limit = 20, int offset = 0}) async {
    final db = await database;
    return await db.query(
      'screenshots',
      orderBy: 'created_date DESC',
      limit: limit,
      offset: offset,
    );
  }

  static Future<String?> getLastId() async {
    final db = await database;
    final result = await db.rawQuery('SELECT MAX(id) as max_id FROM screenshots');
    if (result.isNotEmpty) {
      final value = result.first['max_id'];
      return value != null ? value as String : null;
    }
    return null;
  }
  static Future<String?> getLastIndexedId() async {
    final db = await database;
    final result = await db.query('screenshots',
        columns: ['id'],
        orderBy: 'created_date DESC',
        limit: 1
    );
    return result.isNotEmpty ? result.first['id'] as String : null;
  }
  
  static Future<bool> screenshotExists(String id) async {
    final db = await database;
    final result = await db.query('screenshots', 
      where: 'id = ?', 
      whereArgs: [id],
      limit: 1
    );
    return result.isNotEmpty;
  }
  
  static Future<void> addImageTag(String imageId, String tagName) async {
    final db = await database;
    await db.insert('image_tags', {
      'image_id': imageId,
      'tag_name': tagName,
      'created_date': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }
  
  static Future<List<String>> getImageTags(String imageId) async {
    final db = await database;
    final result = await db.query('image_tags',
      columns: ['tag_name'],
      where: 'image_id = ?',
      whereArgs: [imageId],
    );
    return result.map((row) => row['tag_name'] as String).toList();
  }
  
  static Future<List<String>> getAllTags() async {
    final db = await database;
    final result = await db.query('image_tags',
      columns: ['DISTINCT tag_name'],
      orderBy: 'tag_name',
    );
    return result.map((row) => row['tag_name'] as String).toList();
  }
  
  static Future<List<Map<String, dynamic>>> getAllTagsWithCount() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT tag_name, COUNT(*) as count 
      FROM image_tags 
      GROUP BY tag_name 
      ORDER BY tag_name
    ''');
    return result;
  }
  
  static Future<List<Map<String, dynamic>>> getImagesByTag(String tagName) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT s.* FROM screenshots s
      INNER JOIN image_tags t ON s.id = t.image_id
      WHERE t.tag_name = ?
      ORDER BY s.created_date DESC
    ''', [tagName]);
    return result;
  }
  
  static Future<void> updateTagName(String oldName, String newName) async {
    final db = await database;
    await db.update('image_tags', 
      {'tag_name': newName},
      where: 'tag_name = ?',
      whereArgs: [oldName],
    );
  }
  
  static Future<void> deleteTag(String tagName) async {
    final db = await database;
    await db.delete('image_tags',
      where: 'tag_name = ?',
      whereArgs: [tagName],
    );
  }
}
