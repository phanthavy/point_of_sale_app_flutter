import 'package:client/models/order.dart';
import 'package:client/state/pos_store.dart';
import 'package:client/theme/app_colors.dart';
import 'package:client/utils/format.dart';
import 'package:client/views/table/table_picker.dart';
import 'package:client/widgets/empty_state.dart';
import 'package:flutter/material.dart';

class NewOrderView extends StatelessWidget {
  const NewOrderView({super.key});

  Future<void> _sendToTable(BuildContext context) async {
    final table = await showTablePicker(context, title: 'Send to which table?');
    if (table == null || !context.mounted) return;

    final order = posStore.sendCartToTable(table);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        content: Text(
          'Sent to ${order.table}. Bill total: ${formatKip(order.total)}',
        ),
      ),
    );
    DefaultTabController.of(context).animateTo(1);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: posStore,
      builder: (context, _) {
        final items = posStore.cartItems;
        if (items.isEmpty) {
          return const EmptyState(
            icon: Icons.shopping_basket_outlined,
            title: 'No items yet',
            message: 'Tap + on a product to add it to the order.',
          );
        }

        return Column(
          children: [
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: items.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) => _CartRow(item: items[index]),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.border, width: 2),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Total (${posStore.cartCount} items)',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.textMuted),
                        ),
                      ),
                      Text(
                        formatKip(posStore.cartTotal),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: posStore.clearCart,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          minimumSize: const Size(0, 48),
                        ),
                        child: const Text('Clear'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _sendToTable(context),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            minimumSize: const Size(0, 48),
                          ),
                          icon: const Icon(Icons.table_restaurant),
                          label: const Text(
                            'Send to table',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CartRow extends StatelessWidget {
  final OrderItem item;

  const _CartRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  formatKip(item.price),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          _QtyButton(
            icon: Icons.remove,
            onTap: () => posStore.decrease(item.productId),
          ),
          SizedBox(
            width: 32,
            child: Text(
              '${item.quantity}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          _QtyButton(
            icon: Icons.add,
            onTap: () => posStore.increase(item.productId),
          ),
          SizedBox(
            width: 96,
            child: Text(
              formatKip(item.subtotal),
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primaryLight,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
      ),
    );
  }
}
