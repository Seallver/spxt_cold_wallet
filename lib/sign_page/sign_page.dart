import '../utils/scan_QRcode_page.dart';
import '../utils/auth.dart';
import '../utils/clibAPI.dart';
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
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              title: const Text('Lagrange shard QR Code'),
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
                    },
                    child: const Text('Show Lagrange shard QR Code'),
                  ),
                ),
              ),
            ],

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
            if (transaction.isNotEmpty)
              Text('📒 Transaction: $transaction')
            else
              const Text(
                'No transaction scanned',
                style: TextStyle(color: Colors.grey),
              ),

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
                      try {
                        final Map<String, dynamic> jsonData = jsonDecode(
                          result,
                        );

                        final parsedR = jsonData['R'];
                        final parsedForsSk = jsonData['fors_sk'];

                        if (parsedR != null && parsedForsSk != null) {
                          setState(() {
                            R = parsedR;
                            fors_sk = parsedForsSk;
                          });
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Missing "R" or "fors_sk" field in the scanned JSON.',
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Scanned content is not valid JSON.'),
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Scan to obtain R and fors_sk'),
                ),
              ),
            ),

            const SizedBox(height: 20),
            if (R.isNotEmpty)
              Text('🎲 R: $R')
            else
              const Text('No R scanned', style: TextStyle(color: Colors.grey)),

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
                      try {
                        final Map<String, dynamic> jsonData = jsonDecode(
                          result,
                        );

                        final parsedLevel = jsonData['level'];
                        final parsedRoot = jsonData['root'];

                        if (parsedLevel is int &&
                            parsedRoot is String &&
                            parsedRoot.isNotEmpty) {
                          setState(() {
                            level = parsedLevel;
                            last_root = parsedRoot;
                          });
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Missing "level" or "root" field in the scanned JSON.',
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Scanned content is not valid JSON.'),
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Scan to obtain level and last root'),
                ),
              ),
            ),

            const SizedBox(height: 20),
            if (last_root.isNotEmpty) ...[
              Text('🌲 last root: $last_root'),
              const SizedBox(height: 10),
              Text('🔢 level: $level'),
            ] else
              const Text(
                'No root and level scanned',
                style: TextStyle(color: Colors.grey),
              ),

            const SizedBox(height: 20),
            Center(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: ElevatedButton(
                onPressed: () async {
                  final verified = await authenticateWithBiometrics(context);
                    if (verified) {
                      _signTransaction;
                    }
                },
                child: const Text('Sign'),
                ),
              ),
            ),

            const SizedBox(height: 20),
            Center(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: const Text('sign shard QR Code'),
                            content: SizedBox(
                              width: 200,
                              height: 200,
                              child: QrImageView(
                                data: buildSignShardJson(),
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
                  },
                  child: const Text('Show sign shard QR Code'),
                ),
              ),
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
      'party':selectedKeyData!['party']
    };
    return jsonEncode(jsonMap);
  }

  Future<void> _signTransaction() async {
    if (selectedKeyData == null || transaction.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please prepare the parameters")),
      );
      return;
    }

    sk = selectedKeyData!['sk'];
    pk = selectedKeyData!['pk'];
    t = selectedKeyData!['threshold'];

    final msgPtr = hexStringToUint8Pointer(transaction);
    final skPtr = hexStringToUint8Pointer(sk);
    final fors_skPtr = hexStringToUint8Pointer(fors_sk);
    final pkPtr = hexStringToUint8Pointer(pk);
    final rootPtr = hexStringToUint8Pointer(last_root);
    final RPtr = hexStringToUint8Pointer(R);
    final smPtr = malloc<Uint8>(2048);
    final levelPtr = malloc<Int32>()..value = level;
    final smlenPtr = malloc<Int32>()..value = sm_len;

    final res = spxSign(
      smPtr,
      smlenPtr,
      msgPtr,
      transaction.length ~/ 2,
      RPtr,
      skPtr,
      fors_skPtr,
      pkPtr,
      t,
      rootPtr,
      levelPtr,
    );

    if (res == 0) {
      showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              title: const Text("Sign Success"),
              content: Text("Signature: $sm"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("OK"),
                ),
              ],
            ),
      );
    } else {
      showDialog(
        context: context,
        builder:
            (_) => const AlertDialog(
              title: Text("Sign Failed"),
              content: Text(
                "The call to the C function failed. Please check the parameters or libraries",
              ),
            ),
      );
    }

    level = levelPtr.value;
    sm_len = smlenPtr.value;

    final newRootBytes = rootPtr.asTypedList(64);
    final newRootHex =
        newRootBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    last_root = newRootHex;
    final newSMBytes = smPtr.asTypedList(sm_len);
    final newSMHex =
        newSMBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    sm = newSMHex;


    malloc.free(msgPtr);
    malloc.free(skPtr);
    malloc.free(fors_skPtr);
    malloc.free(pkPtr);
    malloc.free(rootPtr);
    malloc.free(RPtr);
    malloc.free(smPtr);
    malloc.free(levelPtr);
  }
}
