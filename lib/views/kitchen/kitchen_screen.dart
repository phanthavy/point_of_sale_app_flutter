import 'package:client/models/order.dart';
import 'package:client/state/pos_store.dart';
import 'package:client/theme/app_colors.dart';
import 'package:client/utils/format.dart';
import 'package:client/widgets/empty_state.dart';
import 'package:flutter/material.dart';

class KitchenScreen extends StatefulWidget {
  const KitchenScreen({super.key});

  @override
  State<KitchenScreen> createState() => _KitchenScreenState();
}

class _KitchenScreenState extends State<KitchenScreen> {
  bool _showDone = false;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: posStore,
      builder: (context, _) {
        final pending = posStore.pendingTickets;
        final done = posStore.doneTickets;
        final tickets = _showDone ? done : pending;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<bool>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: false,
                      icon: const Icon(Icons.local_fire_department),
                      label: Text('To cook (${pending.length})'),
                    ),
                    ButtonSegment(
                      value: true,
                      icon: const Icon(Icons.check_circle_outline),
                      label: Text('Done (${done.length})'),
                    ),
                  ],
                  selected: {_showDone},
                  onSelectionChanged: (s) =>
                      setState(() => _showDone = s.first),
                ),
              ),
            ),
            Expanded(
              child: tickets.isEmpty
                  ? EmptyState(
                      icon: Icons.soup_kitchen_outlined,
                      title: _showDone
                          ? 'Nothing done yet'
                          : 'No orders to cook',
                      message: _showDone
                          ? 'Finished orders appear here.'
                          : 'New orders sent from tables appear here.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: tickets.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) =>
                          _TicketCard(ticket: tickets[index]),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _TicketCard extends StatelessWidget {
  final KitchenTicket ticket;

  const _TicketCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final accent = ticket.done ? AppColors.border : AppColors.occupied;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ticket.done ? Colors.white : AppColors.occupiedLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.table_restaurant, color: accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ticket.table,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                'Sent ${formatTime(ticket.createdAt)}',
                style: const TextStyle(color: AppColors.textMuted),
              ),
            ],
          ),
          const Divider(height: 20),
          for (final item in ticket.items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Text(
                      '${item.quantity}×',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item.name,
                      style: const TextStyle(fontSize: 17),
                    ),
                  ),
                ],
              ),
            ),
          if (!ticket.done) ...[
            const SizedBox(height: 10),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 46),
              ),
              onPressed: () => posStore.markTicketDone(ticket.id),
              icon: const Icon(Icons.check),
              label: const Text('Done', style: TextStyle(fontSize: 16)),
            ),
          ],
        ],
      ),
    );
  }
}
