import 'package:flutter/material.dart';

class FinalizacaoScreen extends StatelessWidget {
  const FinalizacaoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Using teal accent color from the image
    final Color primaryColor =
        Colors.teal; // Or Colors.cyanAccent[700] or similar

    return Scaffold(
      backgroundColor: primaryColor,
      body: const SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 40.0, vertical: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Obrigado!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 40),
                // Optional: Add an icon or image here if desired
                // Icon(Icons.check_circle_outline, color: Colors.white, size: 80),
                SizedBox(height: 40),
                // Button to navigate back or close the app (optional)
                /*
                ElevatedButton(
                  onPressed: () {
                    // Navigate back to home or close
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    minimumSize: const Size(200, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Voltar ao Início',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                */
              ],
            ),
          ),
        ),
      ),
    );
  }
}
