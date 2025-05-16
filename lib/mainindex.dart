// import 'package:flutter/material.dart';
// import 'dart:ffi';
// import 'clibAPI.dart';
// import 'package:ffi/ffi.dart';

// void mmain() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: Scaffold(
//         appBar: AppBar(title: const Text('SPX Test Demo')),
//         body: const Center(child: SPXTestButton()),
//       ),
//     );
//   }
// }

// class SPXTestButton extends StatefulWidget {
//   const SPXTestButton({super.key});

//   @override
//   State<SPXTestButton> createState() => _SPXTestButtonState();
// }

// class _SPXTestButtonState extends State<SPXTestButton> {
//   String _result = 'Click the button to run spx_test';
//   bool _isLoading = false;

//   // 模拟数据（实际使用时替换为真实数据）
//   final _inputM = [1, 2, 3];  // 模拟 input_m
//   final _R = [4, 5, 6];       // 模拟 R
//   final _inputSk = [7, 8, 9];  // 模拟 input_sk
//   final _inputPk = [10, 11, 12]; // 模拟 input_pk

//   Future<void> _runTest() async {
//     setState(() {
//       _isLoading = true;
//       _result = 'Running...';
//     });

//     try {
//       final signAPI = SignAPI();

//       // 分配内存并填充数据
//       final inputMPtr = _listToPointer(_inputM);
//       final rPtr = _listToPointer(_R);
//       final skPtr = _listToPointer(_inputSk);
//       final pkPtr = _listToPointer(_inputPk);

//       // 调用 C 函数
//       final result = signAPI.spx_test(
//         inputMPtr,
//         _inputM.length,
//         rPtr,
//         skPtr,
//         pkPtr,
//       );

//       // 释放内存
//       calloc.free(inputMPtr);
//       calloc.free(rPtr);
//       calloc.free(skPtr);
//       calloc.free(pkPtr);

//       setState(() {
//         _result = 'Result: $result';
//       });
//     } catch (e) {
//       setState(() {
//         _result = 'Error: $e';
//       });
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

//   // 辅助函数：将 List<int> 转换为 Pointer<Uint8>
//   Pointer<Uint8> _listToPointer(List<int> list) {
//     final ptr = calloc<Uint8>(list.length);
//     for (var i = 0; i < list.length; i++) {
//       ptr[i] = list[i];
//     }
//     return ptr;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         ElevatedButton(
//           onPressed: _isLoading ? null : _runTest,
//           child: const Text('Run SPX Test'),
//         ),
//         const SizedBox(height: 20),
//         if (_isLoading) const CircularProgressIndicator(),
//         const SizedBox(height: 20),
//         Text(_result),
//       ],
//     );
//   }
// }