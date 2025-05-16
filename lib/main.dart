// main.dart
import 'package:flutter/material.dart';
import 'key_page/key_manager_page.dart';
import 'sign_page/sign_page.dart';
import 'utils/check_connection_page.dart';

void main() {
  runApp(MaterialApp(
    home: const CheckConnectionPage(),
    routes: {
      '/main': (context) => const MainMenuPage(),
    },
  ));
}

class MainMenuPage extends StatelessWidget {
  const MainMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SPX Cold Wallet')),
      body: Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: Image.asset('assets/logo.png', width: 300, height: 300),
            ),
            const SizedBox(height: 30),
            Center(
              child: SizedBox(
                width: 200,
                child: ElevatedButton(
                  child: const Text('Key Manager'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ViewKeyPage(),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: SizedBox(
                width: 200,
                child: ElevatedButton(
                  child: const Text('Sign'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SignPage()),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}