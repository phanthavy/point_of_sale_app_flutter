import 'package:client/models/order.dart';
import 'package:client/models/user.dart';
import 'package:client/services/receipt_printer.dart';
import 'package:client/state/auth_store.dart';
import 'package:client/state/pos_store.dart';
import 'package:client/theme/app_colors.dart';
import 'package:client/utils/format.dart';
import 'package:client/views/table/table_picker.dart';
import 'package:client/views/table/transfer_qr_dialog.dart';
import 'package:client/widgets/payment_badge.dart';
import 'package:flutter/material.dart';

void showBillSheet(BuildContext context, int orderId) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => BillSheet(orderId: orderId),
  );
}

class BillSheet extends StatelessWidget {
  final int orderId;

  const BillSheet({super.key, required this.orderId});

  Future<void> _pay(
    BuildContext context,
    Order order,
    PaymentMethod method,
  ) async {
    if (method == PaymentMethod.transfer) {
      final received = await showTransferQrDialog(
        context,
        order,
        staffName: authStore.user?.name ?? '-',
      );
      if (!received || !context.mounted) return;
    }

    final messenger = ScaffoldMessenger.of(context);
    posStore.pay(order.id, method);
    Navigator.pop(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          '${order.table} paid by ${method.label}: ${formatKip(order.total)}',
        ),
      ),
    );
  }

  Future<void> _print(BuildContext context, Order order) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await printReceipt(order, staffName: authStore.user?.name ?? '-');
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not print: $error')),
      );
    }
  }

  Future<void> _move(BuildContext context, Order order) async {
    final toTable = await showTablePicker(
      context,
      title: 'Move ${order.table} to...',
      exclude: order.table,
    );
    if (toTable == null || !context.mounted) return;

    final targetOrder = posStore.openOrderFor(toTable);
    if (targetOrder != null) {
      final merge = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('$toTable already has a bill'),
          content: Text(
            'Merge ${order.table} (${formatKip(order.total)}) into '
            '$toTable (${formatKip(targetOrder.total)})? '
            'They will pay as one bill.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Merge'),
            ),
          ],
        ),
      );
      if (merge != true || !context.mounted) return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final moved = posStore.moveOrder(order.id, toTable);
    Navigator.pop(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          targetOrder == null
              ? 'Moved ${order.table} to $toTable'
              : 'Merged ${order.table} into $toTable. '
                    'New total: ${formatKip(moved.total)}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: posStore,
      builder: (context, _) {
        final order = posStore.orderById(orderId);
        if (order == null) return const SizedBox.shrink();
        final isAdmin = authStore.user?.role == Role.admin;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        order.table,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (order.isPaid)
                      PaymentBadge(method: order.paymentMethod!)
                    else
                      const Text(
                        'UNPAID',
                        style: TextStyle(
                          color: AppColors.occupied,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
                Text(
                  'Bill #${order.id} · opened ${formatDateTime(order.createdAt)}'
                  '${order.isPaid ? '\nPaid ${formatDateTime(order.paidAt!)}' : ''}',
                  style: const TextStyle(color: AppColors.textMuted),
                ),
                const Divider(height: 24),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 320),
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final item in order.items)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 32,
                                child: Text('${item.quantity}×'),
                              ),
                              Expanded(child: Text(item.name)),
                              Text(formatKip(item.subtotal)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      formatKip(order.total),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                if (isAdmin) const SizedBox(height: 16),
                Row(
                  children: [
                    if (!order.isPaid && isAdmin)
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.occupied,
                            side: const BorderSide(color: AppColors.occupied),
                            minimumSize: const Size(0, 48),
                          ),
                          onPressed: () => _move(context, order),
                          icon: const Icon(Icons.swap_horiz),
                          label: const Text('Move table'),
                        ),
                      ),
                    if (order.isPaid && isAdmin)
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            minimumSize: const Size(0, 48),
                          ),
                          onPressed: () => _print(context, order),
                          icon: const Icon(Icons.print_outlined),
                          label: const Text('Print receipt'),
                        ),
                      ),
                  ],
                ),
                if (!order.isPaid && !isAdmin) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F3F2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.lock_outline, color: AppColors.textMuted),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Only admin can move the table, check and print '
                            'the bill.',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (!order.isPaid && isAdmin) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      for (final method in PaymentMethod.values) ...[
                        if (method != PaymentMethod.values.first)
                          const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: method.color,
                              minimumSize: const Size(0, 52),
                            ),
                            onPressed: () => _pay(context, order, method),
                            icon: Icon(method.icon),
                            label: Text(
                              method.label,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
