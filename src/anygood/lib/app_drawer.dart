import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  Future<void> _exportData(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final Map<String, dynamic> exportData = {};

    for (String key in keys) {
      final value = prefs.get(key);
      if (value is int || value is String || value is bool || value is double) {
        exportData[key] = value;
      }
    }

    final String jsonString = json.encode(exportData);

    // In a real app, you'd use a file picker to save the file.
    // For this example, we'll just show a dialog with the data.
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exported Data'),
        content: SingleChildScrollView(child: Text(jsonString)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text(
              'Menu',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.file_upload),
            title: const Text('Export'),
            onTap: () {
              // Close the drawer before showing the dialog

              Navigator.pop(context);
              _exportData(context);
            },
          ),
        ],
      ),
    );
  }
}
