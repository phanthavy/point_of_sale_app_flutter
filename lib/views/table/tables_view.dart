import 'package:client/data/sample_data.dart';
import 'package:client/state/pos_store.dart';
import 'package:client/views/table/bill_sheet.dart';
import 'package:client/views/table/table_tile.dart';
import 'package:flutter/material.dart';

class TablesView extends StatelessWidget {
  const TablesView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: posStore,
      builder: (context, _) => GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: tables.length,
        itemBuilder: (context, index) {
          final table = tables[index];
          final order = posStore.openOrderFor(table);
          return TableTile(
            table: table,
            openOrder: order,
            onTap: order == null
                ? null
                : () => showBillSheet(context, order.id),
          );
        },
      ),
    );
  }
}
