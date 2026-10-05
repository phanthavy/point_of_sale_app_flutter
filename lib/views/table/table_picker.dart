import 'package:client/data/sample_data.dart';
import 'package:client/state/pos_store.dart';
import 'package:client/views/table/table_tile.dart';
import 'package:flutter/material.dart';

/// Returns the chosen table name, or null if cancelled.
Future<String?> showTablePicker(
  BuildContext context, {
  required String title,
  String? exclude,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: double.maxFinite,
        child: GridView.count(
          shrinkWrap: true,
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: [
            for (final table in tables)
              if (table != exclude)
                TableTile(
                  table: table,
                  openOrder: posStore.openOrderFor(table),
                  showTime: false,
                  onTap: () => Navigator.pop(context, table),
                ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    ),
  );
}
