import 'package:flutter/material.dart';

class ContactMessageScreen extends StatelessWidget {
  const ContactMessageScreen({super.key});

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
              Navigator.of(context).pop(), // Go back to Yes/No Confirmation
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
              // Message Text
              const Text(
                'Em breve entraremos em contato',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),
              // Continuar Button (White)
              ElevatedButton(
                onPressed: () {
                  // Navigate to the Finalização Screen
                  Navigator.pushNamed(context, '/finalizacao');
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
