import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black54),
          onPressed: () => Navigator.of(context)
              .pop(), // Go back to previous screen (Inicio)
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Section (Icon and Title)
              const Column(
                children: [
                  SizedBox(height: 30),
                  Icon(Icons.lock_outline, size: 60, color: Colors.grey),
                  SizedBox(height: 10),
                  Text(
                    'Login',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              // Middle Section (Input Fields and Button)
              Column(
                children: [
                  // RA Input Field (Placeholder)
                  TextField(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.person_outline),
                      hintText: 'RA: 22.00370-3', // Placeholder text from image
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Telefone Input Field (Placeholder)
                  TextField(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.phone_outlined),
                      hintText:
                          'Telefone: (11) 91234-1234', // Placeholder text from image
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 40),
                  // Continuar Button
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to Cardapio Screen
                      Navigator.pushNamed(context, '/cardapio');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Continuar',
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                  ),
                ],
              ),
              // Bottom Logo
              Column(children: [
                // Placeholder for Poliedro Colégio Logo
                Image.asset("lib/images/logo_pequeno.png"),
                const Text('Poliedro Colégio',
                    style: TextStyle(color: Colors.grey)),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
