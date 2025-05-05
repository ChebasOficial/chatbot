import 'package:flutter/material.dart';

class ConfirmationOkScreen extends StatelessWidget {
  const ConfirmationOkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Using teal accent color from the image
    const Color primaryColor =
        Colors.teal; // Or Colors.cyanAccent[700] or similar

    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () =>
              Navigator.of(context).pop(), // Go back to Coluna Selection
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Placeholder for the top element (line/indicator) - Assuming similar style
              Container(
                height: 5,
                width: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(
                      0.5), // INFO: Consider replacing deprecated withOpacity
                  borderRadius: BorderRadius.circular(10),
                ),
                margin: const EdgeInsets.only(bottom: 80, left: 80, right: 80),
              ),
              // Ok Button (Green)
              ElevatedButton(
                onPressed: () {
                  // Placeholder action - maybe confirm selection
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Ok',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 40),
              // Continuar Button (White)
              ElevatedButton(
                onPressed: () {
                  // Navigate to Linha/Coluna Selection Screen
                  Navigator.pushNamed(context, '/linha_coluna');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Continuar',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              const Spacer(), // Pushes content to center if needed
            ],
          ),
        ),
      ),
    );
  }
}
