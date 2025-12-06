import 'package:flutter/material.dart';

class BmsControlPage extends StatelessWidget {
  const BmsControlPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BMS控制'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: const Center(
        child: Text('BMS控制页面'),
      ),
    );
  }
}