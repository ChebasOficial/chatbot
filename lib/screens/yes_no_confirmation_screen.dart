import 'package:flutter/material.dart';

class YesNoConfirmationScreen extends StatelessWidget {
  const YesNoConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Using teal accent color from the image
    final Color primaryColor = Colors.teal; // Or Colors.cyanAccent[700] or similar

    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(), // Go back to Linha/Coluna Selection
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
                  color: Colors.white.withOpacity(0.5), // INFO: Consider replacing deprecated withOpacity
                  borderRadius: BorderRadius.circular(10),
                ),
                margin: const EdgeInsets.only(bottom: 80, left: 80, right: 80),
              ),
              // Yes/No Buttons Row
              Row(
                children: [
                  // Sim Button (Green)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Handle Yes action - Placeholder
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
                        'Sim',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Não Button (Red)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Handle No action - Placeholder
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Não',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              // Continuar Button (White)
              ElevatedButton(
                onPressed: () {
                  // Navigate to the Contact Message Screen
                  Navigator.pushNamed(context, '/contact');
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

