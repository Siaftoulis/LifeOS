import 'package:flutter/material.dart';

class EinkReaderView extends StatelessWidget {
  const EinkReaderView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Pure Black and White for E-Ink Displays
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'E-Ink Mode',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Expanded(
              child: SingleChildScrollView(
                child: Text(
                  'High contrast text tailored for minimal refresh rates on e-paper displays. No animations, no greys, strict black-and-white pixel rendering.',
                  style: TextStyle(color: Colors.black, fontSize: 20, height: 1.5, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const Divider(color: Colors.black, thickness: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.black, width: 2),
                  ),
                  child: const Text('< PREV', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
                const Text('Page 42', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.black, width: 2),
                  ),
                  child: const Text('NEXT >', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
