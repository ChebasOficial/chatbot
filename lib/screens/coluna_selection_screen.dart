import 'package:flutter/material.dart';

class ColunaSelectionScreen extends StatelessWidget {
  const ColunaSelectionScreen({super.key});

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
          onPressed: () => Navigator.of(context).pop(), // Go back to Cardapio
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(), // Pushes content down
              // Coluna Button (Placeholder)
              ElevatedButton(
                onPressed: () {
                  // Placeholder action - maybe select 'coluna'
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
                  'coluna', // Placeholder text from image
                  style: TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 20),
              // Coluna: B Button (Placeholder)
              ElevatedButton(
                onPressed: () {
                  // Placeholder action - maybe select 'Coluna: B'
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
                  'Coluna: B', // Placeholder text from image
                  style: TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 40),
              // Continuar Button
              ElevatedButton(
                onPressed: () {
                  // Navigate to Confirmation OK Screen
                  Navigator.pushNamed(context, '/confirmation_ok');
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
              const Spacer(), // Pushes content up
            ],
          ),
        ),
      ),
    );
  }
}
