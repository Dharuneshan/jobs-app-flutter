import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/profile.dart';
import 'package:flutter/foundation.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'jobs_database.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    debugPrint('DatabaseHelper: Creating profiles table...');
    await db.execute('''
      CREATE TABLE profiles(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        phone_number TEXT NOT NULL,
        candidate_type TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    debugPrint('DatabaseHelper: profiles table created.');
  }

  Future<int> insertProfile(Profile profile) async {
    final db = await database;
    debugPrint('DatabaseHelper: Inserting profile: \\${profile.toJson()}');
    final result = await db.insert(
      'profiles',
      {
        'phone_number': profile.phoneNumber,
        'candidate_type': profile.candidateType,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    debugPrint('DatabaseHelper: Insert result: \\$result');
    return result;
  }

  Future<int> updateCandidateType(
      String phoneNumber, String candidateType) async {
    final db = await database;
    return await db.update(
      'profiles',
      {'candidate_type': candidateType},
      where: 'phone_number = ?',
      whereArgs: [phoneNumber],
    );
  }

  Future<Profile?> getProfile(String phoneNumber) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'profiles',
      where: 'phone_number = ?',
      whereArgs: [phoneNumber],
    );

    if (maps.isEmpty) return null;

    return Profile(
      phoneNumber: maps.first['phone_number'],
      candidateType: maps.first['candidate_type'],
    );
  }
}
