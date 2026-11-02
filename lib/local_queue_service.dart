import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'models/client.dart';

/// SQLite-backed queue and sync outbox. Web uses an in-memory fallback because
/// sqflite is not available in browsers.
class LocalQueueService {
  LocalQueueService({this.inMemory = false});

  final bool inMemory;
  Database? _database;
  final Map<String, Map<String, Object?>> _webRows = {};

  static const tableName = 'local_clients';

  Future<Database> get _db async {
    if (kIsWeb) throw UnsupportedError('SQLite is not available on web.');
    if (_database != null) return _database!;
    if (inMemory) {
      _database = await openDatabase(
        ':memory:',
        version: 1,
        onCreate: _createSchema,
      );
    } else {
      final directory = await getDatabasesPath();
      _database = await openDatabase(
        p.join(directory, 'waiting_room.db'),
        version: 1,
        onCreate: _createSchema,
      );
    }
    return _database!;
  }

  Future<void> _createSchema(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableName (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        lat REAL,
        lng REAL,
        created_at TEXT NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0,
        is_deleted INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> insertClientLocally(Client client) async {
    final row = client.toLocalMap();
    if (kIsWeb) {
      _webRows[client.id] = row;
      return;
    }
    await (await _db).insert(
      tableName,
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Client>> getClients() async {
    final rows = kIsWeb
        ? _webRows.values.where((row) => row['is_deleted'] != 1).toList()
        : await (await _db).query(
            tableName,
            where: 'is_deleted = 0',
            orderBy: 'created_at ASC',
          );
    if (kIsWeb) {
      rows.sort(
        (a, b) =>
            (a['created_at']! as String).compareTo(b['created_at']! as String),
      );
    }
    return rows.map(Client.fromMap).toList(growable: false);
  }

  Future<List<Client>> getUnsyncedClients() async {
    final rows = kIsWeb
        ? _webRows.values
              .where((row) => row['is_synced'] == 0 && row['is_deleted'] == 0)
              .toList()
        : await (await _db).query(
            tableName,
            where: 'is_synced = 0 AND is_deleted = 0',
            orderBy: 'created_at ASC',
          );
    return rows.map(Client.fromMap).toList(growable: false);
  }

  Future<List<String>> getPendingDeletes() async {
    if (kIsWeb) {
      return _webRows.values
          .where((row) => row['is_deleted'] == 1)
          .map((row) => row['id']! as String)
          .toList();
    }
    final rows = await (await _db).query(
      tableName,
      columns: ['id'],
      where: 'is_deleted = 1',
    );
    return rows.map((row) => row['id']! as String).toList();
  }

  Future<void> markClientAsSynced(String id) async {
    if (kIsWeb) {
      final row = _webRows[id];
      if (row != null) row['is_synced'] = 1;
      return;
    }
    await (await _db).update(
      tableName,
      {'is_synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> removeClient(String id) async {
    if (kIsWeb) {
      final row = _webRows[id];
      if (row != null && row['is_synced'] == 1) {
        row['is_deleted'] = 1;
      } else {
        _webRows.remove(id);
      }
      return;
    }
    final db = await _db;
    final rows = await db.query(
      tableName,
      columns: ['is_synced'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return;
    if (rows.first['is_synced'] == 1) {
      await db.update(
        tableName,
        {'is_deleted': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    } else {
      await db.delete(tableName, where: 'id = ?', whereArgs: [id]);
    }
  }

  Future<void> finishDelete(String id) async {
    if (kIsWeb) {
      _webRows.remove(id);
      return;
    }
    await (await _db).delete(tableName, where: 'id = ?', whereArgs: [id]);
  }

  /// Merge a full Supabase snapshot, retaining local unsynced rows and queued
  /// deletions. This also reflects deletes made by another connected device.
  Future<void> mergeRemoteClients(List<Client> remoteClients) async {
    final remoteIds = remoteClients.map((client) => client.id).toSet();
    if (kIsWeb) {
      for (final entry in _webRows.entries.toList()) {
        final row = entry.value;
        if (row['is_synced'] == 1 &&
            row['is_deleted'] == 0 &&
            !remoteIds.contains(entry.key)) {
          _webRows.remove(entry.key);
        }
      }
      for (final client in remoteClients) {
        final local = _webRows[client.id];
        if (local == null ||
            (local['is_synced'] == 1 && local['is_deleted'] == 0)) {
          _webRows[client.id] = client.copyWith(isSynced: true).toLocalMap();
        }
      }
      return;
    }
    final db = await _db;
    await db.transaction((txn) async {
      final localRows = await txn.query(
        tableName,
        columns: ['id'],
        where: 'is_synced = 1 AND is_deleted = 0',
      );
      for (final row in localRows) {
        final id = row['id']! as String;
        if (!remoteIds.contains(id)) {
          await txn.delete(
            tableName,
            where: 'id = ? AND is_synced = 1 AND is_deleted = 0',
            whereArgs: [id],
          );
        }
      }
      for (final client in remoteClients) {
        await txn.rawInsert(
          'INSERT INTO $tableName (id, name, lat, lng, created_at, is_synced, is_deleted) '
          'VALUES (?, ?, ?, ?, ?, 1, 0) ON CONFLICT(id) DO UPDATE SET '
          'name=excluded.name, lat=excluded.lat, lng=excluded.lng, '
          'created_at=excluded.created_at, is_synced=1 '
          'WHERE $tableName.is_synced=1 AND $tableName.is_deleted=0',
          [
            client.id,
            client.name,
            client.latitude,
            client.longitude,
            client.createdAt.toUtc().toIso8601String(),
          ],
        );
      }
    });
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
