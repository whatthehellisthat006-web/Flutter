import 'package:flutter/material.dart';
import 'dart:async'; // Required for the Timer class

class WaitingRoomTimestamp extends StatefulWidget {
  const WaitingRoomTimestamp({super.key});

  @override
  State<WaitingRoomTimestamp> createState() => _WaitingRoomTimestampState();
}

class _WaitingRoomTimestampState extends State<WaitingRoomTimestamp> {
  // A variable to hold the current time
  late DateTime _currentTime;
  // A timer to update the time periodically
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    // Initialize the current time when the widget is created
    _currentTime = DateTime.now();

    // Set up a periodic timer to update the state every second
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // Use setState to rebuild the widget with the new time
      setState(() {
        _currentTime = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    // Always cancel timers in dispose to prevent memory leaks!
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Format the time as HH:MM:SS
    final String timeString =
        '${_currentTime.hour.toString().padLeft(2, '0')}:${_currentTime.minute.toString().padLeft(2, '0')}:${_currentTime.second.toString().padLeft(2, '0')}';
        
    return Text(
      'Current time: $timeString',
      style: const TextStyle(fontSize: 14, color: Colors.grey),
    );
  }
}