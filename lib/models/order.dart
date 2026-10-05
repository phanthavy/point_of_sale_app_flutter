import 'package:client/theme/app_colors.dart';
import 'package:flutter/material.dart';

enum PaymentMethod {
  cash('Cash', Icons.payments_outlined, AppColors.cash),
  transfer('Transfer', Icons.qr_code_2, AppColors.transfer);

  const PaymentMethod(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;
}

class OrderItem {
  final int productId;
  final String name;
  final int price;
  final int quantity;

  const OrderItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
  });

  int get subtotal => price * quantity;

  OrderItem copyWith({int? quantity}) => OrderItem(
    productId: productId,
    name: name,
    price: price,
    quantity: quantity ?? this.quantity,
  );

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'name': name,
    'price': price,
    'quantity': quantity,
  };

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
    productId: json['productId'] as int,
    name: json['name'] as String,
    price: json['price'] as int,
    quantity: json['quantity'] as int,
  );
}

List<OrderItem> _itemsFromJson(Object? json) => [
  for (final item in json as List)
    OrderItem.fromJson(item as Map<String, dynamic>),
];

/// One round of items sent to the kitchen for a table.
class KitchenTicket {
  final int id;
  final String table;
  final List<OrderItem> items;
  final DateTime createdAt;
  final bool done;

  const KitchenTicket({
    required this.id,
    required this.table,
    required this.items,
    required this.createdAt,
    this.done = false,
  });

  KitchenTicket copyWith({String? table, bool? done}) => KitchenTicket(
    id: id,
    table: table ?? this.table,
    items: items,
    createdAt: createdAt,
    done: done ?? this.done,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'table': table,
    'items': [for (final item in items) item.toJson()],
    'createdAt': createdAt.toIso8601String(),
    'done': done,
  };

  factory KitchenTicket.fromJson(Map<String, dynamic> json) => KitchenTicket(
    id: json['id'] as int,
    table: json['table'] as String,
    items: _itemsFromJson(json['items']),
    createdAt: DateTime.parse(json['createdAt'] as String),
    done: json['done'] as bool,
  );
}

/// A table's bill. It stays open (unpaid) until the customer leaves and pays.
class Order {
  final int id;
  final String table;
  final List<OrderItem> items;
  final DateTime createdAt;
  final PaymentMethod? paymentMethod;
  final DateTime? paidAt;

  const Order({
    required this.id,
    required this.table,
    required this.items,
    required this.createdAt,
    this.paymentMethod,
    this.paidAt,
  });

  bool get isPaid => paymentMethod != null;
  int get total => items.fold(0, (sum, item) => sum + item.subtotal);
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  Order copyWith({
    String? table,
    List<OrderItem>? items,
    PaymentMethod? paymentMethod,
    DateTime? paidAt,
  }) => Order(
    id: id,
    table: table ?? this.table,
    items: items ?? this.items,
    createdAt: createdAt,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    paidAt: paidAt ?? this.paidAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'table': table,
    'items': [for (final item in items) item.toJson()],
    'createdAt': createdAt.toIso8601String(),
    'paymentMethod': paymentMethod?.name,
    'paidAt': paidAt?.toIso8601String(),
  };

  factory Order.fromJson(Map<String, dynamic> json) {
    final method = json['paymentMethod'] as String?;
    final paidAt = json['paidAt'] as String?;
    return Order(
      id: json['id'] as int,
      table: json['table'] as String,
      items: _itemsFromJson(json['items']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      paymentMethod: method == null
          ? null
          : PaymentMethod.values.byName(method),
      paidAt: paidAt == null ? null : DateTime.parse(paidAt),
    );
  }
}
