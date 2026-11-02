import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'geolocation_service.dart';
import 'local_queue_service.dart';
import 'models/client.dart';

class QueueProvider extends ChangeNotifier {
  QueueProvider({
    required LocalQueueService localQueue,
    SupabaseClient? supabase,
    GeolocationService? geolocation,
  }) : _localQueue = localQueue,
       _supabase = supabase,
       _geolocation = geolocation ?? GeolocationService();

  final LocalQueueService _localQueue;
  final SupabaseClient? _supabase;
  final GeolocationService _geolocation;
  final List<Client> _clients = [];
  StreamSubscription<List<Map<String, dynamic>>>? _remoteSubscription;
  Timer? _retryTimer;
  Future<void>? _syncing;
  bool _disposed = false;
  bool _loading = true;
  String? _syncMessage;

  List<Client> get clients => List.unmodifiable(_clients);
  bool get isLoading => _loading;
  bool get isCloudConfigured => _supabase != null;
  String? get syncMessage => _syncMessage;

  Future<void> initialize() async {
    await _reloadLocal();
    if (_supabase == null) {
      _loading = false;
      _syncMessage = 'Saved on this device';
      _notify();
      return;
    }
    _remoteSubscription = _supabase
        .from('clients')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: true)
        .listen(
          _handleRemoteSnapshot,
          onError: (Object error) => _setSyncMessage('Cloud sync unavailable'),
        );
    await syncPendingChanges();
    _retryTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      unawaited(syncPendingChanges());
    });
    _loading = false;
    _notify();
  }

  Future<void> _handleRemoteSnapshot(List<Map<String, dynamic>> rows) async {
    try {
      final remoteClients = rows
          .map((row) => Client.fromMap(Map<String, Object?>.from(row)))
          .toList();
      await _localQueue.mergeRemoteClients(remoteClients);
      await _reloadLocal();
      _setSyncMessage('Synced with cloud');
      unawaited(syncPendingChanges());
    } catch (_) {
      _setSyncMessage('Cloud sync unavailable');
    }
  }

  Future<void> _reloadLocal() async {
    _clients
      ..clear()
      ..addAll(await _localQueue.getClients());
    _notify();
  }

  Future<void> addClient(String name) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) return;
    final location = await _geolocation.getCurrentLocation();
    final client = Client(
      id: const Uuid().v4(),
      name: cleanName,
      createdAt: DateTime.now().toUtc(),
      latitude: location?.latitude,
      longitude: location?.longitude,
    );
    await _localQueue.insertClientLocally(client);
    _clients.add(client);
    _clients.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    _notify();
    unawaited(syncPendingChanges());
  }

  Future<void> removeClient(String id) async {
    await _localQueue.removeClient(id);
    _clients.removeWhere((client) => client.id == id);
    _notify();
    unawaited(syncPendingChanges());
  }

  Future<void> nextClient() async {
    if (_clients.isNotEmpty) await removeClient(_clients.first.id);
  }

  Future<void> syncPendingChanges() {
    if (_supabase == null || _disposed) return Future.value();
    return _syncing ??= _performSync().whenComplete(() => _syncing = null);
  }

  Future<void> _performSync() async {
    try {
      for (final client in await _localQueue.getUnsyncedClients()) {
        await _supabase!.from('clients').upsert(client.toRemoteMap());
        await _localQueue.markClientAsSynced(client.id);
      }
      for (final id in await _localQueue.getPendingDeletes()) {
        await _supabase!.from('clients').delete().eq('id', id);
        await _localQueue.finishDelete(id);
      }
      await _reloadLocal();
      _setSyncMessage('Synced with cloud');
    } catch (_) {
      _setSyncMessage('Waiting for cloud connection');
    }
  }

  void _setSyncMessage(String message) {
    if (_syncMessage == message) return;
    _syncMessage = message;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _retryTimer?.cancel();
    unawaited(_remoteSubscription?.cancel());
    unawaited(_localQueue.close());
    super.dispose();
  }
}
