import 'package:flutter/material.dart';
import 'dart:math';

// GLOBAL SETTINGS
final appSettings = AppSettings();

class AppSettings extends ChangeNotifier {
  double spacing = 0.0;
  double borderRadius = 0.0;
  bool randomColors = true;
  MaterialColor baseColor = Colors.blue;

  void setSpacing(double value) {
    spacing = value;
    notifyListeners();
  }

  void setBorderRadius(double value) {
    borderRadius = value;
    notifyListeners();
  }

  void setRandomColors(bool value) {
    randomColors = value;
    notifyListeners();
  }

  void setBaseColor(MaterialColor color) {
    baseColor = color;
    notifyListeners();
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Splittable Rectangles',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        // Transparent AppBar just to hold the Drawer hamburger menu icon
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(
            color: Colors.black,
            size: 32,
            shadows: [Shadow(color: Colors.white, blurRadius: 10)], // Make it visible on dark colors
          ),
        ),
        extendBodyBehindAppBar: true, // Let the rectangles fill the entire screen
        drawer: const SettingsDrawer(),
        body: const SplittableRectangle(
          splitDirection: Axis.horizontal,
        ),
      ),
    );
  }
}

class SettingsDrawer extends StatelessWidget {
  const SettingsDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      // ListenableBuilder redraws the drawer when settings change
      child: ListenableBuilder(
        listenable: appSettings,
        builder: (context, _) {
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(color: Colors.black87),
                child: Center(
                  child: Text(
                    'Settings',
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),
                ),
              ),
              ListTile(
                title: const Text('Spacing (Distance)'),
                subtitle: Slider(
                  value: appSettings.spacing,
                  min: 0.0,
                  max: 40.0,
                  onChanged: appSettings.setSpacing,
                ),
              ),
              ListTile(
                title: const Text('Border Radius (Sharpness)'),
                subtitle: Slider(
                  value: appSettings.borderRadius,
                  min: 0.0,
                  max: 100.0,
                  onChanged: appSettings.setBorderRadius,
                ),
              ),
              const Divider(),
              SwitchListTile(
                title: const Text('Random Colors'),
                subtitle: const Text('Disable for color degradation'),
                value: appSettings.randomColors,
                onChanged: appSettings.setRandomColors,
              ),
              // Only show the color options if randomColors is disabled
              if (!appSettings.randomColors)
                ListTile(
                  title: const Text('Base Color'),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _ColorOption(Colors.blue),
                        _ColorOption(Colors.red),
                        _ColorOption(Colors.green),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ColorOption extends StatelessWidget {
  final MaterialColor color;
  const _ColorOption(this.color);

  @override
  Widget build(BuildContext context) {
    final isSelected = appSettings.baseColor == color;
    return GestureDetector(
      onTap: () => appSettings.setBaseColor(color),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.black : Colors.transparent,
            width: 4,
          ),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
          ],
        ),
      ),
    );
  }
}

class SplittableRectangle extends StatefulWidget {
  final Axis splitDirection;

  const SplittableRectangle({super.key, required this.splitDirection});

  @override
  State<SplittableRectangle> createState() => _SplittableRectangleState();
}

class _SplittableRectangleState extends State<SplittableRectangle> {
  bool isSplit = false;
  late Color randomColor;
  late int shadeIndex;

  @override
  void initState() {
    super.initState();
    randomColor = _getRandomColor();
    // Material colors have shade intensities from 100 to 900.
    // We generate a random shade for this specific rectangle.
    shadeIndex = (Random().nextInt(9) + 1) * 100;
  }

  Color _getRandomColor() {
    final random = Random();
    return Color.fromARGB(
      255,
      random.nextInt(256),
      random.nextInt(256),
      random.nextInt(256),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!isSplit) {
      // ListenableBuilder here ensures that every leaf rectangle redraws itself 
      // dynamically as you drag the sliders in the drawer, without losing state!
      return ListenableBuilder(
        listenable: appSettings,
        builder: (context, _) {
          final currentColor = appSettings.randomColors
              ? randomColor
              : appSettings.baseColor[shadeIndex]!;

          return GestureDetector(
            onTap: () {
              setState(() {
                isSplit = true; // Splitting triggers rebuild
              });
            },
            child: Padding(
              // Apply the spacing setting
              padding: EdgeInsets.all(appSettings.spacing / 2),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: currentColor,
                  // Apply the border radius setting
                  borderRadius: BorderRadius.circular(appSettings.borderRadius),
                  border: Border.all(color: Colors.black26, width: 0.5),
                ),
              ),
            ),
          );
        },
      );
    }

    // Once split, we alternate the direction for the next splits
    final nextDirection = widget.splitDirection == Axis.horizontal
        ? Axis.vertical
        : Axis.horizontal;

    // Both halves are their own independent SplittableRectangle
    final children = [
      Expanded(child: SplittableRectangle(splitDirection: nextDirection)),
      Expanded(child: SplittableRectangle(splitDirection: nextDirection)),
    ];

    if (widget.splitDirection == Axis.horizontal) {
      return Row(children: children);
    } else {
      return Column(children: children);
    }
  }
}
