import 'package:client/models/order.dart';
import 'package:client/state/pos_store.dart';
import 'package:client/theme/app_colors.dart';
import 'package:client/utils/format.dart';
import 'package:flutter/material.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  bool _todayOnly = true;

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: posStore,
      builder: (context, _) {
        final orders = _todayOnly
            ? posStore.paidOrders.where((o) => _isToday(o.paidAt!)).toList()
            : posStore.paidOrders;
        final openOrders = posStore.openOrders;
        final unpaid = openOrders.fold(0, (sum, o) => sum + o.total);

        final revenue = orders.fold(0, (sum, o) => sum + o.total);
        final itemsSold = orders.fold(0, (sum, o) => sum + o.itemCount);
        final average = orders.isEmpty ? 0 : revenue ~/ orders.length;

        final revenueByPayment = {
          for (final method in PaymentMethod.values)
            method: orders
                .where((o) => o.paymentMethod == method)
                .fold(0, (sum, o) => sum + o.total),
        };

        final productTotals = <String, ({int quantity, int revenue})>{};
        for (final order in orders) {
          for (final item in order.items) {
            final current = productTotals[item.name];
            productTotals[item.name] = (
              quantity: (current?.quantity ?? 0) + item.quantity,
              revenue: (current?.revenue ?? 0) + item.subtotal,
            );
          }
        }
        final topProducts = productTotals.entries.toList()
          ..sort((a, b) => b.value.quantity.compareTo(a.value.quantity));

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: true, label: Text('Today')),
                ButtonSegment(value: false, label: Text('All time')),
              ],
              selected: {_todayOnly},
              onSelectionChanged: (s) => setState(() => _todayOnly = s.first),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                _StatCard(
                  icon: Icons.attach_money,
                  label: 'Revenue (paid)',
                  value: formatKip(revenue),
                ),
                _StatCard(
                  icon: Icons.receipt_long_outlined,
                  label: 'Paid bills',
                  value: '${orders.length}',
                ),
                _StatCard(
                  icon: Icons.table_restaurant,
                  label: 'Open tables',
                  value: '${openOrders.length}',
                  color: AppColors.occupied,
                ),
                _StatCard(
                  icon: Icons.hourglass_bottom,
                  label: 'Unpaid (open bills)',
                  value: formatKip(unpaid),
                  color: AppColors.occupied,
                ),
                _StatCard(
                  icon: Icons.restaurant_menu,
                  label: 'Items sold',
                  value: '$itemsSold',
                ),
                _StatCard(
                  icon: Icons.trending_up,
                  label: 'Average bill',
                  value: formatKip(average),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const _SectionTitle('Payment methods'),
            for (final method in PaymentMethod.values)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(method.icon, color: method.color),
                title: Text(method.label),
                trailing: Text(
                  formatKip(revenueByPayment[method]!),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            const SizedBox(height: 16),
            const _SectionTitle('Top products'),
            if (topProducts.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No sales yet',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              )
            else
              for (final (index, entry) in topProducts.take(5).indexed)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.primaryLight,
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  title: Text(entry.key),
                  subtitle: Text('${entry.value.quantity} sold'),
                  trailing: Text(
                    formatKip(entry.value.revenue),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const Spacer(),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }
}
