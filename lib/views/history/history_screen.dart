import 'package:client/models/order.dart';
import 'package:client/state/pos_store.dart';
import 'package:client/theme/app_colors.dart';
import 'package:client/utils/format.dart';
import 'package:client/views/table/bill_sheet.dart';
import 'package:client/widgets/empty_state.dart';
import 'package:client/widgets/payment_badge.dart';
import 'package:flutter/material.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  PaymentMethod? _filter;

  /// The day to show, or null for all days.
  DateTime? _day = DateTime.now();

  bool get _isTodaySelected => _day != null && isSameDay(_day!, DateTime.now());

  Future<void> _pickDay() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _day ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      helpText: 'Show bills for',
    );
    if (picked != null) setState(() => _day = picked);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: posStore,
      builder: (context, _) {
        final allPaid = posStore.paidOrders;
        if (allPaid.isEmpty) {
          return const EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'No paid bills yet',
            message: 'Bills appear here after the table pays.',
          );
        }

        final orders = allPaid
            .where((o) => _day == null || isSameDay(o.paidAt!, _day!))
            .where((o) => _filter == null || o.paymentMethod == _filter)
            .toList();
        final total = orders.fold(0, (sum, o) => sum + o.total);
        final pickedPastDay = _day != null && !_isTodaySelected;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('Today'),
                    selected: _isTodaySelected,
                    onSelected: (_) => setState(() => _day = DateTime.now()),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('All days'),
                    selected: _day == null,
                    onSelected: (_) => setState(() => _day = null),
                  ),
                  const SizedBox(width: 8),
                  const Spacer(),
                  Flexible(
                    flex: 100,
                    child: pickedPastDay
                        ? FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                            ),
                            onPressed: _pickDay,
                            icon: const Icon(Icons.calendar_month, size: 18),
                            label: Text(
                              formatDate(_day!),
                              overflow: TextOverflow.ellipsis,
                            ),
                          )
                        : OutlinedButton.icon(
                            onPressed: _pickDay,
                            icon: const Icon(Icons.calendar_month, size: 18),
                            label: const Text(
                              'Pick date',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<PaymentMethod?>(
                  showSelectedIcon: false,
                  segments: [
                    const ButtonSegment(value: null, label: Text('All')),
                    for (final method in PaymentMethod.values)
                      ButtonSegment(
                        value: method,
                        icon: Icon(method.icon),
                        label: Text(method.label),
                      ),
                  ],
                  selected: {_filter},
                  onSelectionChanged: (s) => setState(() => _filter = s.first),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  Text(
                    '${orders.length} bills',
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                  const Spacer(),
                  Text(
                    'Total ${formatKip(total)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: orders.isEmpty
                  ? const Center(child: Text('No bills match this filter'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: orders.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) =>
                          _PaidBillRow(order: orders[index]),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _PaidBillRow extends StatelessWidget {
  final Order order;

  const _PaidBillRow({required this.order});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => showBillSheet(context, order.id),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Icon(Icons.table_restaurant, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.table,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Bill #${order.id} · ${order.itemCount} items\n'
                      'Paid ${formatDateTime(order.paidAt!)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatKip(order.total),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  PaymentBadge(method: order.paymentMethod!),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
