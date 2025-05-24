import 'package:flutter/material.dart';

class ConfirmationScreen extends StatelessWidget {
  final String orderId; // Mantém o ID do Firebase, pode ser útil para consultas futuras
  final double totalValue;
  final String orderNumber; // NOVO: Número do pedido (000-999)

  const ConfirmationScreen({
    Key? key,
    required this.orderId,
    required this.totalValue,
    required this.orderNumber, // Adiciona o parâmetro obrigatório
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedido Confirmado'),
        automaticallyImplyLeading: false, // Impede o botão de voltar automático
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Colors.green,
                size: 100.0,
              ),
              const SizedBox(height: 24.0),
              const Text(
                'Pedido realizado com sucesso!',
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16.0),
              Text(
                'Número do pedido:',
                style: TextStyle(
                  fontSize: 18.0,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                '#$orderNumber', // Exibe o número do pedido formatado
                style: const TextStyle(
                  fontSize: 28.0, // Aumenta o tamanho para destaque
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24.0),
              Text(
                'Valor total: R\$ ${totalValue.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 32.0),
              const Text(
                'Agradecemos pela sua compra!',
                style: TextStyle(
                  fontSize: 18.0,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48.0),
              ElevatedButton(
                onPressed: () {
                  // Volta para a tela inicial (ou a tela desejada após confirmação)
                  // Removendo todas as rotas anteriores para evitar voltar ao chat
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/inicio', // Certifique-se que '/inicio' é a rota correta
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32.0,
                    vertical: 16.0,
                  ),
                ),
                child: const Text(
                  'Voltar para o Início',
                  style: TextStyle(fontSize: 18.0),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

