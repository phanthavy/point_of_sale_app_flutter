import 'dart:convert';

import 'package:client/models/order.dart';
import 'package:client/models/product.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PosStore extends ChangeNotifier {
  static const _storageKey = 'pos_data_v1';

  final Map<int, OrderItem> _cart = {};
  final List<Order> _orders = [];
  final List<KitchenTicket> _tickets = [];
  int _nextOrderId = 1;
  int _nextTicketId = 1;
  SharedPreferences? _prefs;

  /// Loads saved data and saves every change from now on.
  void attach(SharedPreferences prefs) {
    _prefs = prefs;
    final raw = prefs.getString(_storageKey);
    if (raw == null) return;

    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      _cart
        ..clear()
        ..addAll({
          for (final json in data['cart'] as List)
            (json['productId'] as int): OrderItem.fromJson(json),
        });
      _orders
        ..clear()
        ..addAll([
          for (final json in data['orders'] as List) Order.fromJson(json),
        ]);
      _tickets
        ..clear()
        ..addAll([
          for (final json in data['tickets'] as List)
            KitchenTicket.fromJson(json),
        ]);
      _nextOrderId = data['nextOrderId'] as int;
      _nextTicketId = data['nextTicketId'] as int;
    } catch (error) {
      debugPrint('Could not load saved POS data: $error');
    }
  }

  @override
  void notifyListeners() {
    super.notifyListeners();
    _prefs?.setString(
      _storageKey,
      jsonEncode({
        'cart': [for (final item in _cart.values) item.toJson()],
        'orders': [for (final order in _orders) order.toJson()],
        'tickets': [for (final ticket in _tickets) ticket.toJson()],
        'nextOrderId': _nextOrderId,
        'nextTicketId': _nextTicketId,
      }),
    );
  }

  /// Oldest first, so the kitchen cooks in order.
  List<KitchenTicket> get pendingTickets =>
      _tickets.where((t) => !t.done).toList();

  /// Most recent first.
  List<KitchenTicket> get doneTickets =>
      _tickets.where((t) => t.done).toList().reversed.toList();

  void markTicketDone(int ticketId) {
    final index = _tickets.indexWhere((t) => t.id == ticketId);
    if (index == -1) return;
    _tickets[index] = _tickets[index].copyWith(done: true);
    notifyListeners();
  }

  void reset() {
    _cart.clear();
    _orders.clear();
    _tickets.clear();
    _nextOrderId = 1;
    _nextTicketId = 1;
    notifyListeners();
  }

  List<OrderItem> get cartItems => _cart.values.toList();
  int get cartCount => _cart.values.fold(0, (sum, item) => sum + item.quantity);
  int get cartTotal => _cart.values.fold(0, (sum, item) => sum + item.subtotal);

  List<Order> get openOrders => _orders.where((o) => !o.isPaid).toList();

  /// Most recently paid first.
  List<Order> get paidOrders =>
      _orders.where((o) => o.isPaid).toList()
        ..sort((a, b) => b.paidAt!.compareTo(a.paidAt!));

  Order? openOrderFor(String table) {
    for (final order in _orders) {
      if (!order.isPaid && order.table == table) return order;
    }
    return null;
  }

  Order? orderById(int id) {
    for (final order in _orders) {
      if (order.id == id) return order;
    }
    return null;
  }

  int quantityOf(int productId) => _cart[productId]?.quantity ?? 0;

  void add(Product product) {
    final existing = _cart[product.id];
    _cart[product.id] = existing == null
        ? OrderItem(
            productId: product.id,
            name: product.name,
            price: product.price,
            quantity: 1,
          )
        : existing.copyWith(quantity: existing.quantity + 1);
    notifyListeners();
  }

  void increase(int productId) {
    final existing = _cart[productId];
    if (existing == null) return;
    _cart[productId] = existing.copyWith(quantity: existing.quantity + 1);
    notifyListeners();
  }

  void decrease(int productId) {
    final existing = _cart[productId];
    if (existing == null) return;
    if (existing.quantity <= 1) {
      _cart.remove(productId);
    } else {
      _cart[productId] = existing.copyWith(quantity: existing.quantity - 1);
    }
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  /// Adds the cart to the table's open bill, or opens a new bill for it.
  Order sendCartToTable(String table) {
    final existing = openOrderFor(table);
    final Order order;
    if (existing == null) {
      order = Order(
        id: _nextOrderId++,
        table: table,
        items: cartItems,
        createdAt: DateTime.now(),
      );
      _orders.add(order);
    } else {
      order = existing.copyWith(items: _merge(existing.items, cartItems));
      _orders[_orders.indexOf(existing)] = order;
    }
    _tickets.add(
      KitchenTicket(
        id: _nextTicketId++,
        table: table,
        items: cartItems,
        createdAt: DateTime.now(),
      ),
    );
    _cart.clear();
    notifyListeners();
    return order;
  }

  /// Moves an open bill to another table. If that table already has an open
  /// bill, the two are merged into it and the moved bill is removed.
  Order moveOrder(int orderId, String toTable) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    final source = _orders[index];
    final target = openOrderFor(toTable);

    final Order result;
    if (target == null) {
      result = source.copyWith(table: toTable);
      _orders[index] = result;
    } else {
      result = target.copyWith(items: _merge(target.items, source.items));
      _orders[_orders.indexOf(target)] = result;
      _orders.removeAt(index);
    }
    for (var i = 0; i < _tickets.length; i++) {
      final ticket = _tickets[i];
      if (!ticket.done && ticket.table == source.table) {
        _tickets[i] = ticket.copyWith(table: toTable);
      }
    }
    notifyListeners();
    return result;
  }

  Order pay(int orderId, PaymentMethod method) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    final order = _orders[index].copyWith(
      paymentMethod: method,
      paidAt: DateTime.now(),
    );
    _orders[index] = order;
    notifyListeners();
    return order;
  }

  List<OrderItem> _merge(List<OrderItem> current, List<OrderItem> added) {
    final merged = {for (final item in current) item.productId: item};
    for (final item in added) {
      final existing = merged[item.productId];
      merged[item.productId] = existing == null
          ? item
          : existing.copyWith(quantity: existing.quantity + item.quantity);
    }
    return merged.values.toList();
  }
}

final posStore = PosStore();
