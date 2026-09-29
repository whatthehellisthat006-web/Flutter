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

6 / 7

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
// This is crucial! Cancel the timer when the widget is removed from the tree
// to prevent memory leaks and unnecessary processing.
_timer.cancel();
super.dispose();
}
@override
Widget build(BuildContext context) {
// Format the date and time to a readable string
final formattedTime = _currentTime.toString().split('.')[0];
return Text(
'Current Time: $formattedTime',
style: const TextStyle(
fontSize: 14,
color: Colors.black54,
),
);
}
}