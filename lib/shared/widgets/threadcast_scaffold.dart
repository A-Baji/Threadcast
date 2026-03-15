import 'package:flutter/material.dart';

class ThreadcastScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;

  const ThreadcastScaffold({super.key, required this.body, this.appBar});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: body,
    );
  }
}
