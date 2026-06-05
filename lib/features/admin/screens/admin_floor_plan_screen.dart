import 'package:flutter/material.dart';

class AdminFloorPlanScreen extends StatelessWidget {
  const AdminFloorPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Floor Plan Management'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Floor Plan Management - Coming Soon'),
      ),
    );
  }
}