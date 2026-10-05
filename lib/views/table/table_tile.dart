import 'package:client/models/order.dart';
import 'package:client/theme/app_colors.dart';
import 'package:client/utils/format.dart';
import 'package:flutter/material.dart';

class TableTile extends StatelessWidget {
  final String table;
  final Order? openOrder;
  final VoidCallback? onTap;
  final bool showTime;

  const TableTile({
    super.key,
    required this.table,
    required this.openOrder,
    this.onTap,
    this.showTime = true,
  });

  @override
  Widget build(BuildContext context) {
    final order = openOrder;
    final occupied = order != null;
    final color = occupied ? AppColors.occupied : AppColors.textMuted;

    return Material(
      color: occupied ? AppColors.occupiedLight : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: occupied ? AppColors.occupied : AppColors.border,
          width: 2,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.table_restaurant, color: color),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  table,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  occupied ? formatKip(order.total) : 'Free',
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: occupied ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              if (occupied && showTime)
                Text(
                  'since ${formatTime(order.createdAt)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
