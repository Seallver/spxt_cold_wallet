import 'dart:convert';
import 'dart:ffi';
import 'package:flutter/material.dart';
import 'package:ffi/ffi.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../utils/clibAPI.dart';
import '../utils/scan_QRcode_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FinalResultPage extends StatefulWidget {
  final Pointer<SSS_ctx> ctxPtr;
  final int party;
  final int threshold;
  final int participants;
  final String prime;
  final String account;
  final String note;

  const FinalResultPage({
    super.key,
    required this.account,
    required this.ctxPtr,
    required this.party,
    required this.threshold,
    required this.participants,
    required this.prime,
    required this.note,
  });

  @override
  State<FinalResultPage> createState() => _FinalResultPageState();
}

class _FinalResultPageState extends State<FinalResultPage> {
  String? _blindSkHex;
  String? _pk;
  String? _sk;
  String? _lgrg;
  int res = -1;

  void _onGenBlindSKPressed(BuildContext context) {
    final blindSkPtr = calloc<Uint8>(1024); // 分配足够大的字符串缓冲区
    res = genShards(widget.ctxPtr, blindSkPtr.cast<Utf8>());

    final skHex = blindSkPtr.cast<Utf8>().toDartString();
    calloc.free(blindSkPtr);

    setState(() {
      _blindSkHex = skHex;
    });

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Result'),
        content: Text('Return: $res\nblind_sk:\n$skHex'),
      ),
    );
  }


  void _onShowQRCodePressed(BuildContext context) {
    if (_blindSkHex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please gen blind-sk first')),
      );
      return;
    }

    final data = {'blind_sk': _blindSkHex!};

    final jsonStr = jsonEncode(data);

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Blind SK QR Code'),
            content: SizedBox(
              width: 200,
              height: 200,
              child: QrImageView(
                data: jsonStr,
                version: QrVersions.auto,
                size: 200.0,
              ),
            ),
          ),
    );
  }

  void _onScanQRCodePressed(BuildContext context) async {
    final scannedJson = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScanPage()),
    );

    if (scannedJson == null) return;

    try {
      final decoded = jsonDecode(scannedJson);
      final pk = decoded['pk'];
      if (pk == null) {
        throw Exception('QR code missing "pk" field');
      }

      setState(() {
        _pk = pk;
      });

      showDialog(
        context: context,
        builder:
            (_) =>
                AlertDialog(title: const Text('pk'), content: Text('pk:\n$pk')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid QR code format')));
    }
  }

  void _onSaveKeyPressed(BuildContext context) async {
    final skBuf = calloc<Uint8>(1024);     // 分配足够大的空间存字符串
    final lgrgBuf = calloc<Uint8>(1024);

    sssGetParams(widget.ctxPtr, skBuf.cast<Utf8>(), lgrgBuf.cast<Utf8>());

    final skHex = skBuf.cast<Utf8>().toDartString();
    final lgrgHex = lgrgBuf.cast<Utf8>().toDartString();

    calloc.free(skBuf);
    calloc.free(lgrgBuf);

    setState(() {
      _sk = skHex;
      _lgrg = lgrgHex;
    });

    // if (_pk == null || _sk == null || _lgrg == null) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(
    //       content: Text('Please generate all keys and scan pk first'),
    //     ),
    //   );
    //   return;
    // }

    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getStringList('private_key_index') ?? [];

    final keyName = '${widget.account}_${keys.length}';
    final keyObject = {
      'account': widget.account,
      'party': widget.party.toString(),
      'sk': _sk,
      'pk': _pk,
      'lagrange_shard': _lgrg,
      'threshold': widget.threshold.toString(),
      'participants': widget.participants.toString(),
      'prime': widget.prime,
      'note': widget.note,
    };

    await prefs.setString(keyName, jsonEncode(keyObject));
    keys.add(keyName);
    await prefs.setStringList('private_key_index', keys);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('spx key saved')),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DKG')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('received ctxPtr: ${widget.ctxPtr}'),
            const SizedBox(height: 20),
            Center(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: ElevatedButton(
                  onPressed: () => _onGenBlindSKPressed(context),
                  child: const Text(
                    'gen blind-sk',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            if (res == 0) ...[
              const SizedBox(height: 20),
              Center(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.8,
                  child: ElevatedButton(
                    onPressed: () => _onShowQRCodePressed(context),
                    child: const Text(
                      'Show blind-sk QR code',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              child: ElevatedButton(
                onPressed: () => _onScanQRCodePressed(context),
                child: const Text(
                  'Scan pk',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              child: ElevatedButton(
                onPressed: () {
                  _onSaveKeyPressed(context);
                  sssFree(widget.ctxPtr);
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: const Text(
                  'Save Key',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
