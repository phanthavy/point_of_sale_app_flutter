import 'package:client/models/order.dart';
import 'package:flutter/material.dart';

class PaymentBadge extends StatelessWidget {
  final PaymentMethod method;

  const PaymentBadge({super.key, required this.method});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: method.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(method.icon, size: 14, color: method.color),
          const SizedBox(width: 4),
          Text(
            method.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: method.color,
            ),
          ),
        ],
      ),
    );
  }
}
