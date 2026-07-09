import 'menu.dart';

class Order {
  final int id;
  final int quantity;
  final int totalPrice;
  final String status;
  final String createdAt;
  final Menu? menu;

  Order({
    required this.id,
    required this.quantity,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
    this.menu,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: (json['id'] as num).toInt(),
      quantity: (json['quantity'] as num).toInt(),
      totalPrice: (json['totalPrice'] as num).toInt(),
      status: (json['status'] ?? 'Menunggu').toString(),
      // Sequelize usually returns createdAt as ISO string
      createdAt: (json['createdAt'] ?? '').toString(),
      menu: json['Menu'] != null ? Menu.fromJson(json['Menu']) : null,
    );
  }
}

