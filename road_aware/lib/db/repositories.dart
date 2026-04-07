// lib/db/repositories.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sqflite/sqflite.dart';
import 'package:latlong2/latlong.dart';
import 'app_db.dart';

String _requireUserId() {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    throw StateError('No signed-in user found.');
  }
  return user.uid;
}

class TripRepo {
  Future<int> startTrip({required bool simulated}) async {
    final Database db = await AppDb.instance.db;
    final now = DateTime.now().millisecondsSinceEpoch;
    final userId = _requireUserId();

    final id = await db.insert('trips', {
      'user_id': userId,
      'start_time': now,
      'end_time': null,
      'is_simulated': simulated ? 1 : 0,
      'score': null,
    });

    return id;
  }

  Future<void> endTrip(int tripId) async {
    final Database db = await AppDb.instance.db;
    final now = DateTime.now().millisecondsSinceEpoch;
    final userId = _requireUserId();

    await db.update(
      'trips',
      {'end_time': now},
      where: 'id = ? AND user_id = ?',
      whereArgs: [tripId, userId],
    );
  }

  Future<void> updateScore(int tripId, int score) async {
    final Database db = await AppDb.instance.db;
    final userId = _requireUserId();

    await db.update(
      'trips',
      {'score': score},
      where: 'id = ? AND user_id = ?',
      whereArgs: [tripId, userId],
    );
  }
}

class EventRepo {
  Future<void> logEvent({
    required int tripId,
    required String type,
    double? severity,
    double? lat,
    double? lon,
    DateTime? time,
  }) async {
    final Database db = await AppDb.instance.db;
    final ts = (time ?? DateTime.now()).millisecondsSinceEpoch;
    final userId = _requireUserId();

    await db.insert('events', {
      'trip_id': tripId,
      'user_id': userId,
      'type': type,
      'severity': severity,
      'lat': lat,
      'lon': lon,
      'timestamp': ts,
    });
  }

  Future<Map<String, int>> eventCounts(int tripId) async {
    final Database db = await AppDb.instance.db;
    final userId = _requireUserId();

    final rows = await db.rawQuery('''
      SELECT type, COUNT(*) AS c
      FROM events
      WHERE trip_id = ? AND user_id = ?
      GROUP BY type
    ''', [tripId, userId]);

    final out = <String, int>{};
    for (final r in rows) {
      out[r['type'] as String] = (r['c'] as int);
    }
    return out;
  }
}

class ScoreService {
  Future<int> computeScore(int tripId) async {
    final counts = await EventRepo().eventCounts(tripId);
    final brakes = counts['brake'] ?? 0;
    final accels = counts['accel'] ?? 0;

    final points = await RoutePointRepo().getRoutePoints(tripId);
    double distanceInKm = 0.0;
    const distanceTool = Distance();

    if (points.length >= 2) {
      for (int i = 0; i < points.length - 1; i++) {
        final p1 = LatLng(
          (points[i]['lat'] as num).toDouble(),
          (points[i]['lon'] as num).toDouble(),
        );
        final p2 = LatLng(
          (points[i + 1]['lat'] as num).toDouble(),
          (points[i + 1]['lon'] as num).toDouble(),
        );
        distanceInKm += distanceTool.as(LengthUnit.Kilometer, p1, p2);
      }
    }

    if (distanceInKm < 1.0) distanceInKm = 1.0;

    final double brakePenalty = brakes * 5.0;
    final double accelPenalty = accels * 3.0;
    final double totalPenalty = (brakePenalty + accelPenalty) / distanceInKm;

    int score = (100.0 - totalPenalty).round();

    if (score < 0) score = 0;
    if (score > 100) score = 100;

    return score;
  }
}

class TripSummary {
  final int id;
  final DateTime startTime;
  final DateTime? endTime;
  final bool simulated;
  final int? score;

  TripSummary({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.simulated,
    required this.score,
  });

  factory TripSummary.fromRow(Map<String, Object?> row) {
    return TripSummary(
      id: row['id'] as int,
      startTime: DateTime.fromMillisecondsSinceEpoch(row['start_time'] as int),
      endTime: row['end_time'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row['end_time'] as int),
      simulated: (row['is_simulated'] as int) == 1,
      score: row['score'] as int?,
    );
  }
}

class EventRow {
  final int id;
  final int tripId;
  final String type;
  final double? severity;
  final double? lat;
  final double? lon;
  final DateTime time;

  EventRow({
    required this.id,
    required this.tripId,
    required this.type,
    required this.severity,
    required this.lat,
    required this.lon,
    required this.time,
  });

  factory EventRow.fromRow(Map<String, Object?> row) {
    return EventRow(
      id: row['id'] as int,
      tripId: row['trip_id'] as int,
      type: row['type'] as String,
      severity: (row['severity'] as num?)?.toDouble(),
      lat: (row['lat'] as num?)?.toDouble(),
      lon: (row['lon'] as num?)?.toDouble(),
      time: DateTime.fromMillisecondsSinceEpoch(row['timestamp'] as int),
    );
  }
}

extension TripRepoQueries on TripRepo {
  Future<List<TripSummary>> latestTrips({int limit = 30}) async {
    final Database db = await AppDb.instance.db;
    final userId = _requireUserId();

    final rows = await db.query(
      'trips',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'start_time DESC',
      limit: limit,
    );
    return rows.map(TripSummary.fromRow).toList();
  }
}

extension EventRepoQueries on EventRepo {
  Future<List<EventRow>> eventsForTrip(int tripId) async {
    final Database db = await AppDb.instance.db;
    final userId = _requireUserId();

    final rows = await db.query(
      'events',
      where: 'trip_id = ? AND user_id = ?',
      whereArgs: [tripId, userId],
      orderBy: 'timestamp DESC',
    );
    return rows.map(EventRow.fromRow).toList();
  }
}

class RoutePointRepo {
  Future<void> addPoint({
    required int tripId,
    required double lat,
    required double lon,
    double? speed,
    DateTime? time,
  }) async {
    final Database db = await AppDb.instance.db;
    final ts = (time ?? DateTime.now()).millisecondsSinceEpoch;
    final userId = _requireUserId();

    await db.insert('route_points', {
      'trip_id': tripId,
      'user_id': userId,
      'lat': lat,
      'lon': lon,
      'speed': speed,
      'timestamp': ts,
    });
  }

  Future<int> pointCount(int tripId) async {
    final Database db = await AppDb.instance.db;
    final userId = _requireUserId();

    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM route_points WHERE trip_id = ? AND user_id = ?',
      [tripId, userId],
    );
    return (rows.first['c'] as int?) ?? 0;
  }

  Future<List<Map<String, dynamic>>> getRoutePoints(int tripId) async {
    final Database db = await AppDb.instance.db;
    final userId = _requireUserId();

    return await db.query(
      'route_points',
      where: 'trip_id = ? AND user_id = ?',
      whereArgs: [tripId, userId],
      orderBy: 'timestamp ASC',
    );
  }
}