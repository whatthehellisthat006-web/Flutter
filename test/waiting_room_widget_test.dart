import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:waiting_room_app/geolocation_service.dart';
import 'package:waiting_room_app/local_queue_service.dart';
import 'package:waiting_room_app/main.dart';
import 'package:waiting_room_app/models/client.dart';
import 'package:waiting_room_app/queue_provider.dart';

class NoLocation extends GeolocationService {
  @override
  Future<QueueLocation?> getCurrentLocation() async => null;
}

class MemoryQueue extends LocalQueueService {
  final _clients = <String, Client>{};

  void seed(Client client) => _clients[client.id] = client;

  @override
  Future<List<Client>> getClients() async => _clients.values.toList();

  @override
  Future<void> insertClientLocally(Client client) async {
    _clients[client.id] = client;
  }

  @override
  Future<void> removeClient(String id) async {
    _clients.remove(id);
  }

  @override
  Future<void> close() async {}
}

void main() {
  testWidgets('adding clients and tapping Next Client updates the queue', (
    tester,
  ) async {
    final provider = QueueProvider(
      localQueue: MemoryQueue(),
      geolocation: NoLocation(),
    );
    await provider.initialize();
    await provider.addClient('Client A');
    await provider.addClient('Client B');
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(home: WaitingRoomScreen()),
      ),
    );

    expect(find.text('Clients in Queue: 2'), findsOneWidget);

    await tester.tap(find.byKey(const Key('nextClientButton')));
    await tester.pump();

    expect(find.text('Client A'), findsNothing);
    expect(find.text('Client B'), findsOneWidget);
    expect(find.text('Clients in Queue: 1'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    provider.dispose();
  });

  testWidgets('shows captured location for a queue entry', (tester) async {
    final local = MemoryQueue()
      ..seed(
        Client(
          id: 'with-location',
          name: 'Sam',
          createdAt: DateTime.utc(2026, 1, 1),
          latitude: 51.5074,
          longitude: -0.1278,
        ),
      );
    final provider = QueueProvider(
      localQueue: local,
      geolocation: NoLocation(),
    );
    await provider.initialize();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(home: WaitingRoomScreen()),
      ),
    );

    expect(find.text('Sam'), findsOneWidget);
    expect(find.textContaining('51.5074, -0.1278'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    provider.dispose();
  });
}
