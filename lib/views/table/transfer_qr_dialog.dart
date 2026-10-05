import 'package:client/data/bank_info.dart';
import 'package:client/models/order.dart';
import 'package:client/services/receipt_printer.dart';
import 'package:client/theme/app_colors.dart';
import 'package:client/utils/format.dart';
import 'package:client/widgets/fake_qr_code.dart';
import 'package:flutter/material.dart';

/// Shows the bill's order list, a print button and the transfer QR.
/// Returns true once staff confirm the transfer arrived.
Future<bool> showTransferQrDialog(
  BuildContext context,
  Order order, {
  required String staffName,
}) async {
  Future<void> print(BuildContext dialogContext) async {
    final messenger = ScaffoldMessenger.of(dialogContext);
    try {
      await printReceipt(order, staffName: staffName);
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not print: $error')),
      );
    }
  }

  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      scrollable: true,
      titlePadding: EdgeInsets.zero,
      title: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: const BoxDecoration(
          color: AppColors.transfer,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance, color: Colors.white),
            SizedBox(width: 8),
            Text(
              bankName,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${order.table} · Bill #${order.id}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F3F2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                for (final item in order.items)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        SizedBox(width: 28, child: Text('${item.quantity}×')),
                        Expanded(child: Text(item.name)),
                        Text(formatKip(item.subtotal)),
                      ],
                    ),
                  ),
                const Divider(height: 16),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Total',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(
                      formatKip(order.total),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.transfer,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              minimumSize: const Size(0, 44),
            ),
            onPressed: () => print(context),
            icon: const Icon(Icons.print_outlined),
            label: const Text('Print bill'),
          ),
          const SizedBox(height: 16),
          const Text(
            'Scan to pay',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: 8),
          Center(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.transfer, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: FakeQrCode(data: transferQrData(order), size: 180),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            bankAccountName,
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const Text(
            bankAccountNumber,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: 8),
          const Text(
            'Demo QR only, not a real bank account',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: AppColors.danger),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: AppColors.transfer),
          onPressed: () => Navigator.pop(context, true),
          icon: const Icon(Icons.check),
          label: const Text('Payment received'),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
