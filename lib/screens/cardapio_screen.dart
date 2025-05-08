import 'package:flutter/material.dart';
import 'yes_no_confirmation_screen.dart';

class CardapioScreen extends StatefulWidget {
  const CardapioScreen({super.key});

  @override
  State<CardapioScreen> createState() => _CardapioScreenState();
}

class _CardapioScreenState extends State<CardapioScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black54),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Cardápio',
            style:
                TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon:
                const Icon(Icons.shopping_cart_outlined, color: Colors.black54),
            onPressed: () {/* Navega para o carrinho ou mostra resumo */},
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: ListView(
                  children: [
                    const SizedBox(height: 20),
                    Center(
                      child: Image.network(
                        'https://via.placeholder.com/80',
                        height: 80,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.fastfood,
                                size: 80, color: Colors.orange),
                      ),
                    ),
                    const SizedBox(height: 30),
                    _buildMenuItem('Refrigerante Lata', 'R\$5.00'),
                    const SizedBox(height: 15),
                    _buildMenuItem('Pão de Queijo', 'R\$3.50'),
                    const SizedBox(height: 15),
                    _buildMenuItem('Bolo de Pote', 'R\$8.00'),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 20.0, top: 10.0),
                child: Column(
                  children: [
                    ElevatedButton(
                      // --- onPressed
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext dialogContext) {
                            return Dialog(
                              backgroundColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(1000),
                              ),
                              child: const YesNoConfirmationScreen(),
                            );
                          },
                        );
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
                    const SizedBox(height: 20),
                    Column(children: [
                      Image.asset(
                        "lib/images/logo_pequeno.png",
                        height: 40,
                        errorBuilder: (context, error, stackTrace) =>
                            const Text('Logo',
                                style: TextStyle(color: Colors.grey)),
                      ),
                      const SizedBox(height: 5),
                      const Text('Poliedro Colégio',
                          style: TextStyle(color: Colors.grey)),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(String title, String price) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 16)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange[300],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              price,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
