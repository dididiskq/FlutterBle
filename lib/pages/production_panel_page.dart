import 'package:flutter/material.dart';

class ProductionPanelPage extends StatelessWidget {
  const ProductionPanelPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('生产操作面板'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: const Center(
        child: Text('生产操作面板页面'),
      ),
    );
  }
}