import 'package:cloud_firestore/cloud_firestore.dart';

class CounterProvider {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Método para obter o próximo número de pedido sequencial
  Future<int> getNextOrderNumber() async {
    // Referência para o documento do contador na coleção 'counters'
    final counterRef = _firestore.collection('counters').doc('order_number');

    // Usar transação para garantir atomicidade e evitar conflitos
    return _firestore.runTransaction<int>((transaction) async {
      // Obter o documento atual
      final snapshot = await transaction.get(counterRef);

      // Valor atual do contador
      int currentValue = 0;

      // Se o documento existir, obter o valor atual
      if (snapshot.exists) {
        currentValue = snapshot.data()?['value'] ?? 0;
      }

      // Calcular o próximo valor (reiniciar após 999)
      int nextValue = currentValue + 1;
      if (nextValue > 999) {
        nextValue = 1; // Reiniciar em 1 quando ultrapassar 999
      }

      // Atualizar o documento com o novo valor
      transaction.set(
          counterRef, {'value': nextValue}, SetOptions(merge: true));

      // Retornar o próximo valor
      return nextValue;
    });
  }
}
