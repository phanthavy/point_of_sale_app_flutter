import 'package:client/state/pos_store.dart';
import 'package:client/theme/app_colors.dart';
import 'package:client/views/order/new_order_view.dart';
import 'package:client/views/table/tables_view.dart';
import 'package:flutter/material.dart';

class OrderScreen extends StatelessWidget {
  const OrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          ListenableBuilder(
            listenable: posStore,
            builder: (context, _) => TabBar(
              labelColor: AppColors.primary,
              indicatorColor: AppColors.primary,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              tabs: [
                Tab(text: 'New order (${posStore.cartCount})'),
                Tab(text: 'Tables (${posStore.openOrders.length} open)'),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(children: [NewOrderView(), TablesView()]),
          ),
        ],
      ),
    );
  }
}
