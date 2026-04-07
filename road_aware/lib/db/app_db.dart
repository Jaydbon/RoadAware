// lib/db/app_db.dart
import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class AppDb {
  AppDb._();
  static final AppDb instance = AppDb._();

  Database? _db;

  Future<Database> get db async {
    final existing = _db;
    if (existing != null) return existing;

    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'road_aware.db');

    _db = await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE trips (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT NOT NULL,
            start_time INTEGER NOT NULL,
            end_time INTEGER,
            is_simulated INTEGER NOT NULL DEFAULT 0,
            score INTEGER
          );
        ''');

        await db.execute('''
          CREATE TABLE events (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            trip_id INTEGER NOT NULL,
            user_id TEXT NOT NULL,
            type TEXT NOT NULL,
            severity REAL,
            lat REAL,
            lon REAL,
            timestamp INTEGER NOT NULL,
            FOREIGN KEY(trip_id) REFERENCES trips(id) ON DELETE CASCADE
          );
        ''');

        await db.execute('''
          CREATE TABLE route_points (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            trip_id INTEGER NOT NULL,
            user_id TEXT NOT NULL,
            lat REAL NOT NULL,
            lon REAL NOT NULL,
            speed REAL,
            timestamp INTEGER NOT NULL,
            FOREIGN KEY(trip_id) REFERENCES trips(id) ON DELETE CASCADE
          );
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            "ALTER TABLE trips ADD COLUMN user_id TEXT NOT NULL DEFAULT ''",
          );
          await db.execute(
            "ALTER TABLE events ADD COLUMN user_id TEXT NOT NULL DEFAULT ''",
          );
          await db.execute(
            "ALTER TABLE route_points ADD COLUMN user_id TEXT NOT NULL DEFAULT ''",
          );
        }
      },
    );

    return _db!;
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}