import 'package:flutter/material.dart';

class UnsupportedDeviceScreen extends StatelessWidget {
  const UnsupportedDeviceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Threadcast requires Android 16 / iOS 26 or later to generate podcasts. Support for older devices is coming soon.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
