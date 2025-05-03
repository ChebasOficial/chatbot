import 'package:flutter/material.dart';

class InicioScreen extends StatelessWidget {
  const InicioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Section (Time and Logo)
              Column(
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    '04:28:21 PM', // Placeholder time
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 20),
                  // Placeholder for Poliedro Food Logo
                  const Column(
                    children: [
                      Icon(Icons.restaurant_menu, size: 50, color: Colors.orange), // Placeholder logo
                      Text(
                        'Poliedro Food',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              // Middle Section (Buttons and Info)
              Column(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to Login Screen
                      Navigator.pushNamed(context, '/login');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      minimumSize: const Size(double.infinity, 60),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Pedidos',
                      style: TextStyle(fontSize: 18, color: Colors.black87),
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Placeholder for Weather/Info Card
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.wb_sunny, color: Colors.orange, size: 30),
                            SizedBox(width: 10),
                            Text(
                              '16°',
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Sábado, 12 Agosto', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            Text('São Caetano do Sul', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Bottom Logo
              const Column(
                children: [
                  // Placeholder for Poliedro Colégio Logo
                  Icon(Icons.apps, size: 40, color: Colors.blue), // Placeholder logo
                  Text('Poliedro Colégio', style: TextStyle(color: Colors.grey)),
                ]
              ),
            ],
          ),
        ),
      ),
    );
  }
}

