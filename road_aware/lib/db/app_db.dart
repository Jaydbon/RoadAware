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
      version: 1,
      onCreate: (db, version) async {
        // Trips (session grouping)
        await db.execute('''
          CREATE TABLE trips (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            start_time INTEGER NOT NULL,
            end_time INTEGER,
            is_simulated INTEGER NOT NULL DEFAULT 0,
            score INTEGER
          );
        ''');

        // Events (what your teammate requested)
        await db.execute('''
          CREATE TABLE events (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            trip_id INTEGER NOT NULL,
            type TEXT NOT NULL,
            severity REAL,
            lat REAL,
            lon REAL,
            timestamp INTEGER NOT NULL,
            FOREIGN KEY(trip_id) REFERENCES trips(id) ON DELETE CASCADE
          );
        ''');

        // Optional: route points (safe to include now even if unused)
        await db.execute('''
          CREATE TABLE route_points (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            trip_id INTEGER NOT NULL,
            lat REAL NOT NULL,
            lon REAL NOT NULL,
            speed REAL,
            timestamp INTEGER NOT NULL,
            FOREIGN KEY(trip_id) REFERENCES trips(id) ON DELETE CASCADE
          );
        ''');
      },
    );

    return _db!;
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}