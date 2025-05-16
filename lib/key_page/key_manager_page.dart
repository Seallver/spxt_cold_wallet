import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'key_gen_page.dart';
import '../utils/auth.dart';

class ViewKeyPage extends StatefulWidget {
  const ViewKeyPage({super.key});

  @override
  State<ViewKeyPage> createState() => _ViewKeyPageState();
}

class _ViewKeyPageState extends State<ViewKeyPage> {
  List<String> keyNames = [];

  @override
  void initState() {
    super.initState();
    _loadKeyList();
  }

  Future<void> _loadKeyList() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getStringList('private_key_index') ?? [];
    setState(() {
      keyNames = keys;
    });
  }

  void _navigateToDetail(String keyName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => KeyDetailPage(keyName: keyName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Key List')),
      body: ListView.builder(
        itemCount: keyNames.length,
        itemBuilder: (context, index) {
          final keyName = keyNames[index];
          return ListTile(
            title: Text(keyName),
            onTap: () => _navigateToDetail(keyName),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () async {
                final verified = await authenticateWithBiometrics(context);
                if (verified) {
                  _confirmDeleteKey(keyName);
                }
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final verified = await authenticateWithBiometrics(context);
          if (verified) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const KeyGenPage()),
            ).then((_) => _loadKeyList());
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
  Future<void> _confirmDeleteKey(String keyName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this key? This operation cannot be restored.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getStringList('private_key_index') ?? [];
      keys.remove(keyName);
      await prefs.remove(keyName);
      await prefs.setStringList('private_key_index', keys);

      setState(() {
        keyNames = keys;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The key has been deleted.')),
      );
    }
  }
}

class KeyDetailPage extends StatelessWidget {
  final String keyName;
  const KeyDetailPage({super.key, required this.keyName});

  Future<Map<String, dynamic>> _loadKeyObject() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(keyName);
    if (jsonStr == null) return {};
    return jsonDecode(jsonStr);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(keyName)),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _loadKeyObject(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final keyData = snapshot.data ?? {};
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('account: ${keyData['account'] ?? "null"}', style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 10),
                Text('party: ${keyData['party'] ?? "null"}', style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 10),
                Text('sk: ${keyData['sk'] ?? "null"}', style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 10),
                Text('pk: ${keyData['pk'] ?? "null"}', style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 10),
                Text('lagrange_shard: ${keyData['lagrange_shard'] ?? "null"}', style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 10),
                Text('t: ${keyData['threshold'] ?? "null"}', style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 10),
                Text('note: ${keyData['note'] ?? "null"}', style: const TextStyle(fontSize: 16)),
              ],
            ),
          );
        },
      ),
    );
  }
}
