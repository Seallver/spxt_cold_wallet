import 'dart:convert';
import 'package:flutter/material.dart';

import 'key_gen_page_2.dart';
import '../utils/scan_QRcode_page.dart';

class KeyGenPage extends StatefulWidget {
  const KeyGenPage({super.key});

  @override
  State<KeyGenPage> createState() => _KeyGenPageState();
}

class _KeyGenPageState extends State<KeyGenPage> {
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _partyController = TextEditingController();
  final TextEditingController _thresholdController = TextEditingController();
  final TextEditingController _participantsController = TextEditingController();
  final TextEditingController _primeController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();



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
            const SizedBox(height: 10),
            TextField(
              controller: _partyController,
              decoration: const InputDecoration(labelText: 'input party'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _participantsController,
              decoration: const InputDecoration(labelText: 'input n'),
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
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _primeController,
                    decoration: const InputDecoration(labelText: 'input prime'),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: () async {
                    final scanResult = await Navigator.push<String>(
                      context,
                      MaterialPageRoute(builder: (_) => const ScanPage()),
                    );

                    if (scanResult != null && scanResult.isNotEmpty) {
                      try {
                        final json = jsonDecode(scanResult);
                        final prime = json['prime']?.toString();

                        if (prime != null && prime.isNotEmpty) {
                          setState(() {
                            _primeController.text = prime;
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Prime set from QR code')),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('QR code missing "prime" field')),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Invalid QR code format')),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: ElevatedButton(
                    onPressed: () {
                      final account = _accountController.text.trim();
                      final party = _partyController.text.trim();
                      final t = _thresholdController.text.trim();
                      final n = _participantsController.text.trim();
                      final prime = _primeController.text.trim();
                      final note = _noteController.text.trim();

                      // 检查必填字段
                      if (account.isEmpty || party.isEmpty || t.isEmpty || n.isEmpty || prime.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please input params')),
                        );
                        return;
                      }

                      // 检查 t 和 n 是有效数字
                      final tInt = int.tryParse(t);
                      final nInt = int.tryParse(n);
                      if (tInt == null || nInt == null || tInt <= 0 || nInt <= 0 || tInt >= nInt) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please input valid t and n')),
                        );
                        return;
                      }

                      // 跳转到新页面
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => KeyResultPage(
                            account: account,
                            party: party,
                            threshold: t,
                            participants: n,
                            prime: prime,
                            note: note,
                          ),
                        ),
                      );
                    },
                    child: const Text('Continue'),
                  ),

              )
            ),
          ],
        ),
      ),
    );
  }

}
