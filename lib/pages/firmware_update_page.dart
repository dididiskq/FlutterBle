import 'package:flutter/material.dart';

class FirmwareUpdatePage extends StatelessWidget {
  const FirmwareUpdatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('固件升级'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: const Center(
        child: Text('固件升级页面'),
      ),
    );
  }
}