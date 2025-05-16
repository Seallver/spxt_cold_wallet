import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class CheckConnectionPage extends StatefulWidget {
  const CheckConnectionPage({super.key});

  @override
  State<CheckConnectionPage> createState() => _CheckConnectionPageState();
}

class _CheckConnectionPageState extends State<CheckConnectionPage> {
  bool? isBluetoothOff;
  bool? isNetworkOff;

  @override
  void initState() {
    super.initState();
    _checkAll();
  }

  Future<void>  _checkAll() async {
    final bluetoothState = await FlutterBluePlus.adapterState.first;
    final connectivityResult = await Connectivity().checkConnectivity();

    setState(() {
      isBluetoothOff = (bluetoothState != BluetoothAdapterState.on);
      isNetworkOff = (connectivityResult == ConnectivityResult.none);
    });
  }

  Widget _buildStatusRow(String title, bool? isOff) {
    if (isOff == null) return const SizedBox(); 
    return ListTile(
      leading: Icon(
        isOff ? Icons.check_circle : Icons.cancel,
        color: isOff ? Colors.green : Colors.red,
        size: 32,
      ),
      title: Text(title, style: const TextStyle(fontSize: 18)),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool? allOff = (isBluetoothOff == true) && (isNetworkOff == true);

    return Scaffold(
      appBar: AppBar(title: const Text('Connection status check')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text('Please make sure that both Bluetooth and the network are turned off before continuing', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            _buildStatusRow('Bluetooth off', isBluetoothOff),
            _buildStatusRow('Network off', isNetworkOff),
            const Spacer(),
            ElevatedButton(
              onPressed: (allOff == true) ? () {
                Navigator.pushReplacementNamed(context, '/main');
              } : _checkAll,
              child: Text(allOff == true ? 'continue' : 'recheck'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
