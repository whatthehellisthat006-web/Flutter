import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:waiting_room_app/geolocation_service.dart';
import 'package:waiting_room_app/local_queue_service.dart';
import 'package:waiting_room_app/queue_provider.dart';

class NoLocation extends GeolocationService {
  @override
  Future<QueueLocation?> getCurrentLocation() async => null;
}

class FixedLocation extends GeolocationService {
  @override
  Future<QueueLocation?> getCurrentLocation() async =>
      const QueueLocation(37.7749, -122.4194);
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('local queue stores entries and removes the first client', () async {
    final local = LocalQueueService(inMemory: true);
    final provider = QueueProvider(
      localQueue: local,
      geolocation: NoLocation(),
    );
    await provider.initialize();
    await provider.addClient('Client A');
    await provider.addClient('Client B');

    await provider.nextClient();

    expect(provider.clients.map((client) => client.name), ['Client B']);
    expect((await local.getClients()).single.name, 'Client B');
    provider.dispose();
  });

  test('blank names are ignored', () async {
    final provider = QueueProvider(
      localQueue: LocalQueueService(inMemory: true),
      geolocation: NoLocation(),
    );
    await provider.addClient('   ');
    expect(provider.clients, isEmpty);
    provider.dispose();
  });

  test('new client stores captured coordinates', () async {
    final provider = QueueProvider(
      localQueue: LocalQueueService(inMemory: true),
      geolocation: FixedLocation(),
    );

    await provider.addClient('Visitor');

    expect(provider.clients.single.latitude, 37.7749);
    expect(provider.clients.single.longitude, -122.4194);
    provider.dispose();
  });
}
