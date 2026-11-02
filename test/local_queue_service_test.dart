import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:waiting_room_app/local_queue_service.dart';
import 'package:waiting_room_app/models/client.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('insertClientLocally stores an unsynced client', () async {
    final service = LocalQueueService(inMemory: true);
    final client = Client(
      id: 'test-123',
      name: 'Alice',
      createdAt: DateTime(2024, 1, 1),
      latitude: 40.71,
      longitude: -74.00,
    );

    await service.insertClientLocally(client);

    final unsynced = await service.getUnsyncedClients();
    expect(unsynced, hasLength(1));
    expect(unsynced.single.name, 'Alice');
    expect(unsynced.single.latitude, 40.71);
    await service.close();
  });
}
