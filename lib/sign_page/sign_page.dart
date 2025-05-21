import '../utils/scan_QRcode_page.dart';
import '../utils/auth.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:qr_flutter/qr_flutter.dart';

class SignPage extends StatefulWidget {
  const SignPage({super.key});

  @override
  State<SignPage> createState() => _SignPageState();
}

class _SignPageState extends State<SignPage> {
  List<String> keyNames = [];
  String? selectedKey;

  Map<String, dynamic>? selectedKeyData;
  String sm = "";
  int sm_len = 0;
  String transaction = "";
  String sk = "";
  String fors_sk = "";
  String pk = "";
  String last_root = "";
  String R = "";
  int t = 0;
  int level = 0;

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

  Future<void> _loadKeyData(String keyName) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(keyName);
    if (jsonStr != null) {
      final data = jsonDecode(jsonStr);
      setState(() {
        selectedKey = keyName;
        selectedKeyData = data;
      });
    }
  }

  Pointer<Uint8> hexStringToUint8Pointer(String hex) {
    // 每两个字符代表一个字节
    final length = hex.length ~/ 2;
    final ptr = malloc<Uint8>(length);

    for (int i = 0; i < length; i++) {
      final byteHex = hex.substring(i * 2, i * 2 + 2);
      final byteValue = int.parse(byteHex, radix: 16);
      ptr[i] = byteValue;
    }

    return ptr;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Center(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: ElevatedButton(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ScanPage()),
                    );
                    if (result != null &&
                        result is String &&
                        result.isNotEmpty) {
                      setState(() {
                        transaction = result;
                      });
                    }
                  },
                  child: const Text('Scan to obtain transaction'),
                ),
              ),
            ),

            const SizedBox(height: 20),
            if (transaction.isNotEmpty) ...[
              Text('📒 Transaction: $transaction'),

              const SizedBox(height: 50),
              const Text(
                'Please select the key pair to be used：',
                style: TextStyle(fontSize: 17),
              ),

              const SizedBox(height: 10),
              DropdownButton<String>(
                value: selectedKey,
                hint: const Text('select key'),
                isExpanded: true,
                items:
                    keyNames.map((keyName) {
                      return DropdownMenuItem(
                        value: keyName,
                        child: Text(keyName),
                      );
                    }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    _loadKeyData(value);
                  }
                },
              ),

              const SizedBox(height: 20),
              if (selectedKeyData != null) ...[
                Text('👤 account: ${selectedKeyData!['account'] ?? "null"}'),
                const SizedBox(height: 10),
                Text('📝 note: ${selectedKeyData!['note'] ?? "null"}'),
              ] else
                const Text(
                  'No key selected',
                  style: TextStyle(color: Colors.grey),
                ),

              if (selectedKeyData != null &&
                  selectedKeyData!['lagrange_shard'] != null) ...[
                const SizedBox(height: 20),
                Center(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.8,
                    child: ElevatedButton(
                      onPressed: () async {
                        final verified = await authenticateWithBiometrics(
                          context,
                        );
                        // final verified = true;
                        if (verified) {
                          showDialog(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  title: const Text('Authorization QR Code'),
                                  content: SizedBox(
                                    width: 200,
                                    height: 200,
                                    child: QrImageView(
                                      data: buildLagrangeShardJson(),
                                      version: QrVersions.auto,
                                      size: 200,
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Close'),
                                    ),
                                  ],
                                ),
                          );
                        }
                      },
                      child: const Text('Show Authorization QR Code'),
                    ),
                  ),
                ),
              ],
            ] else
              const Text(
                'No transaction scanned',
                style: TextStyle(color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }

  String buildSignShardJson() {
    final Map<String, dynamic> jsonMap = {
      'level': level,
      'sm': sm,
      'root': last_root,
    };
    return jsonEncode(jsonMap);
  }

  String buildLagrangeShardJson() {
    final Map<String, dynamic> jsonMap = {
      'lagrange_shard': selectedKeyData!['lagrange_shard'],
      'party': selectedKeyData!['party'],
      'prime': selectedKeyData!['prime'],
      'pk': selectedKeyData!['pk'],
    };
    return jsonEncode(jsonMap);
  }
}
