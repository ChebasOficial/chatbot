enum OrderStatus { pending, inProgress, completed, archived }

// Extensão para converter OrderStatus para String
extension OrderStatusExtension on OrderStatus {
  String get value {
    switch (this) {
      case OrderStatus.pending:
        return 'pending';
      case OrderStatus.inProgress:
        return 'inProgress';
      case OrderStatus.completed:
        return 'completed';
      case OrderStatus.archived:
        return 'archived';
      default:
        return 'pending';
    }
  }

  // Método para converter String para OrderStatus
  static OrderStatus fromString(String status) {
    switch (status) {
      case 'pending':
        return OrderStatus.pending;
      case 'inProgress':
        return OrderStatus.inProgress;
      case 'completed':
        return OrderStatus.completed;
      case 'archived':
        return OrderStatus.archived;
      default:
        return OrderStatus.pending;
    }
  }
}
