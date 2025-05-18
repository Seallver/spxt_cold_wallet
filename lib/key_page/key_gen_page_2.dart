import 'dart:convert';
import 'package:flutter/material.dart';
import '../utils/clibAPI.dart';
import '../utils/scan_QRcode_page.dart';
import 'package:ffi/ffi.dart';
import 'dart:ffi';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:typed_data';
import 'key_gen_page_3.dart';


class KeyResultPage extends StatefulWidget {
  final String account;
  final String party;
  final String threshold;
  final String participants;
  final String prime;
  final String note;

  const KeyResultPage({
    super.key,
    required this.account,
    required this.party,
    required this.threshold,
    required this.participants,
    required this.prime,
    required this.note,
  });

  @override
  State<KeyResultPage> createState() => _KeyResultPageState();
}

class _KeyResultPageState extends State<KeyResultPage> {
  List<Map<String, String>> _shares = [];
  String _dkgResult = '';
  String? _currentQrData;
  int? _selectedJ;

  Pointer<SSS_ctx> _ctxPtr = nullptr;

  @override
  void initState() {
    super.initState();
    _initCtx();

    // 合法选择项，排除自己的编号
    final n = int.parse(widget.participants);
    final exclude = int.parse(widget.party);
    final candidates =
        List.generate(n, (i) => i + 1).where((j) => j != exclude).toList();

    _selectedJ = candidates.isNotEmpty ? candidates.first : null;
  }

  Future<void> _initCtx() async {
    final primePtr = widget.prime.toNativeUtf8();
    _ctxPtr =
        sssNew(
          primePtr,
          int.parse(widget.participants),
          int.parse(widget.threshold),
          int.parse(widget.party),
        );
    malloc.free(primePtr);

    setState(() {
      _dkgResult = _ctxPtr == nullptr ? 'failed to init ctx' : 'context ready';
    });
  }

  Future<void> _runAccess(int j) async {
    // 分配 Utf8 缓冲区
    final random = calloc<Uint8>(1024);
    final share = calloc<Uint8>(1024);

    final result = accessShare(
      _ctxPtr,
      j,
      random.cast<Utf8>(),
      share.cast<Utf8>(),
    );

    final rStr = random.cast<Utf8>().toDartString();
    final yStr = share.cast<Utf8>().toDartString();

    calloc.free(random);
    calloc.free(share);

    final src = int.parse(widget.party);

    setState(() {
      if (result == 0) {
        final jsonData = jsonEncode({'src': src, 'r': rStr, 's': yStr});
        _currentQrData = jsonData;
      }
    });
  }


  // @override
  // void dispose() {
  //   if (_ctxPtr != nullptr) {
  //     sssFree(_ctxPtr.cast<SSS_ctx>());
  //   }
  //   super.dispose();
  // }

  @override
  Widget build(BuildContext context) {
    final n = int.parse(widget.participants);

    return Scaffold(
      appBar: AppBar(title: const Text('DKG')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child:
            _dkgResult != 'context ready'
                ? Center(child: Text(_dkgResult))
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                    Text(
                      'Select Destination:',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 下拉选择 j
                    DropdownButton<int>(
                      value: _selectedJ,
                      items:
                          List.generate(n, (index) => index + 1)
                              .where((j) => j != int.parse(widget.party))
                              .map(
                                (j) => DropdownMenuItem(
                                  value: j,
                                  child: Text('$j'),
                                ),
                              )
                              .toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedJ = val;
                        });
                      },
                    ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // 生成二维码按钮
                    Center(
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.8,
                        child: ElevatedButton(
                          onPressed:
                              _selectedJ == null
                                  ? null
                                  : () => _runAccess(_selectedJ!),
                          child: const Text(
                            'Generate QR Code',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 二维码区域，占用剩余空间
                    Expanded(
                      child: Center(
                        child:
                            _currentQrData != null
                                ? QrImageView(
                                  data: _currentQrData!,
                                  version: QrVersions.auto,
                                  size: 250,
                                )
                                : const Text(
                                  'Click the button to generate a QR code',
                                ),
                      ),
                    ),
                    const Divider(),
                    const SizedBox(height: 20),
                    Center(
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.8,
                        child: ElevatedButton(
                          onPressed: _scanQRCode,
                          child: const Text(
                            'Scan QR Code',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    Text('Received Shares:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _shares.length,
                        itemBuilder: (context, index) {
                          final share = _shares[index];
                          return ListTile(
                            leading: Text('Party ${share['src']}'),
                            title: Text('r: ${share['r']}\ns: ${share['s']}', style: const TextStyle(fontSize: 13)),
                          );
                        },
                      ),
                    ),

                    const Divider(),
                    const SizedBox(height: 20),
                    Center(
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.8,
                        child: ElevatedButton(
                          onPressed: _ctxPtr == nullptr
                          ? null
                          : () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => FinalResultPage(
                                    account: widget.account,
                                    ctxPtr: _ctxPtr,
                                    party: int.parse(widget.party),
                                    threshold: int.parse(widget.threshold),
                                    participants: int.parse(widget.participants),
                                    prime: widget.prime,
                                    note: widget.note,
                                  ),
                                ),
                              );
                            },
                            child: const Text(
                              'Continue',
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                            ),
                        ),  
                      ),
                    ),


                  ],
                ),

                
      ),

      
    );
  }
  
  Future<void> _scanQRCode() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ScanPage()),
    );

    if (result != null && result is String) {
      try {
        final Map<String, dynamic> jsonData = jsonDecode(result);
        final int src = jsonData['src'];
        final String rHex = jsonData['r'];
        final String sHex = jsonData['s'];

        // 把 hex 转 byte
        final rBytes = Uint8List.fromList(
          List.generate(rHex.length ~/ 2, (i) => int.parse(rHex.substring(2 * i, 2 * i + 2), radix: 16))
        );
        final sBytes = Uint8List.fromList(
          List.generate(sHex.length ~/ 2, (i) => int.parse(sHex.substring(2 * i, 2 * i + 2), radix: 16))
        );

        // 分配 FFI 内存
        final rPtr = calloc<Uint8>(rBytes.length);
        final sPtr = calloc<Uint8>(sBytes.length);
        for (int i = 0; i < rBytes.length; i++) {
          rPtr[i] = rBytes[i];
        }
        for (int i = 0; i < sBytes.length; i++) {
          sPtr[i] = sBytes[i];
        }

        // 调用 C 函数聚合 share
        final ret = aggregateShare(_ctxPtr, src, rPtr.cast<Utf8>(), sPtr.cast<Utf8>());

        calloc.free(rPtr);
        calloc.free(sPtr);

        if (ret != 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to aggregate share')),
          );
          return;
        }

        // 更新 UI
        setState(() {
          _shares.add({'src': '$src', 'r': rHex, 's': sHex});
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid QR data')),
        );
      }
    }
  }


  
}
