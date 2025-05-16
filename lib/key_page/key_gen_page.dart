import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KeyGenPage extends StatefulWidget {
  const KeyGenPage({super.key});

  @override
  State<KeyGenPage> createState() => _KeyGenPageState();
}

class _KeyGenPageState extends State<KeyGenPage> {
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _skController = TextEditingController();
  final TextEditingController _pkController = TextEditingController();
  final TextEditingController _partyController = TextEditingController();
  final TextEditingController _lagrangeController = TextEditingController();
  final TextEditingController _thresholdController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  Future<void> _saveKey() async {
    final account = _accountController.text.trim();
    final sk = _skController.text.trim();
    final pk = _pkController.text.trim();
    final party = _partyController.text.trim();
    final t = _thresholdController.text.trim();
    final lagrg = _lagrangeController.text.trim();
    final note = _noteController.text.trim();

    if (sk.isEmpty ||
        pk.isEmpty ||
        account.isEmpty ||
        t.isEmpty ||
        lagrg.isEmpty ||
        party.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('please input all fields')));
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getStringList('private_key_index') ?? [];

    final keyName = '${account}_${keys.length}';
    final keyObject = {
      'account': account,
      'party': party,
      'sk': sk,
      'pk': pk,
      'lagrange_shard': lagrg,
      'threshold': t,
      'note': note,
    };

    await prefs.setString(keyName, jsonEncode(keyObject));
    keys.add(keyName);
    await prefs.setStringList('private_key_index', keys);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('spx key saved')));

    setState(() {
      _accountController.clear();
      _skController.clear();
      _pkController.clear();
      _partyController.clear();
      _lagrangeController.clear();
      _noteController.clear();
      _thresholdController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gen key')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _accountController,
              decoration: const InputDecoration(labelText: 'input account'),
            ),
            TextField(
              controller: _skController,
              decoration: const InputDecoration(labelText: 'input sk'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _pkController,
              decoration: const InputDecoration(labelText: 'input pk'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _lagrangeController,
              decoration: const InputDecoration(
                labelText: 'input lagrange shard',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _partyController,
              decoration: const InputDecoration(labelText: 'input party'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _thresholdController,
              decoration: const InputDecoration(labelText: 'input t'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(labelText: 'note'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _saveKey, child: const Text('save key')),
          ],
        ),
      ),
    );
  }
}
