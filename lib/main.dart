import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'local_queue_service.dart';
import 'queue_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final url = const String.fromEnvironment('SUPABASE_URL');
  final publicKey = const String.fromEnvironment('SUPABASE_ANON_KEY');
  SupabaseClient? supabase;
  if (url.isNotEmpty && publicKey.isNotEmpty) {
    try {
      await Supabase.initialize(url: url, publishableKey: publicKey);
      supabase = Supabase.instance.client;
      try {
        await supabase.auth.signInAnonymously();
      } catch (_) {
        // Public queue policies also allow the anon database role if anonymous
        // authentication is disabled for the Supabase project.
      }
    } catch (_) {
      // The local queue remains usable if the cloud configuration is invalid.
    }
  }
  runApp(WaitingRoomApp(supabase: supabase));
}

class WaitingRoomApp extends StatelessWidget {
  const WaitingRoomApp({super.key, this.supabase});

  final SupabaseClient? supabase;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (_) =>
        QueueProvider(localQueue: LocalQueueService(), supabase: supabase)
          ..initialize(),
    child: MaterialApp(
      title: 'Waiting Room',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF216E66)),
        useMaterial3: true,
      ),
      home: const WaitingRoomScreen(),
    ),
  );
}

class WaitingRoomScreen extends StatefulWidget {
  const WaitingRoomScreen({super.key});

  @override
  State<WaitingRoomScreen> createState() => _WaitingRoomScreenState();
}

class _WaitingRoomScreenState extends State<WaitingRoomScreen> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _addClient(QueueProvider queue) async {
    await queue.addClient(_nameController.text);
    _nameController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final queue = context.watch<QueueProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Waiting Room'),
        centerTitle: true,
        actions: [
          IconButton(
            key: const Key('nextClientButton'),
            tooltip: 'Next Client',
            onPressed: queue.clients.isEmpty ? null : queue.nextClient,
            icon: const Icon(Icons.skip_next),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'Client name',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _addClient(queue),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => _addClient(queue),
                    child: const Text('Add'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'Clients in Queue: ${queue.clients.length}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  Flexible(
                    child: Text(
                      queue.syncMessage ?? 'Starting…',
                      textAlign: TextAlign.end,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: queue.isLoading && queue.clients.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : queue.clients.isEmpty
                    ? const Center(child: Text('No one in the queue yet.'))
                    : ListView.builder(
                        itemCount: queue.clients.length,
                        itemBuilder: (context, index) {
                          final client = queue.clients[index];
                          final location =
                              client.latitude == null ||
                                  client.longitude == null
                              ? 'Location not captured'
                              : '${client.latitude!.toStringAsFixed(4)}, '
                                    '${client.longitude!.toStringAsFixed(4)}';
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Text('${index + 1}'),
                              ),
                              title: Text(client.name),
                              subtitle: Text(
                                '$location · ${_formatTime(client.createdAt)}',
                              ),
                              trailing: IconButton(
                                tooltip: 'Remove ${client.name}',
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => queue.removeClient(client.id),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              FilledButton.icon(
                onPressed: queue.clients.isEmpty ? null : queue.nextClient,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Next Client'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
