import 'package:client/models/product.dart';
import 'package:client/state/pos_store.dart';
import 'package:flutter_test/flutter_test.dart';

const beer = Product(id: 1, name: 'Beer', price: 25000, categoryId: 1);
const fries = Product(id: 2, name: 'Fries', price: 35000, categoryId: 2);

void main() {
  test('moving a bill to a free table keeps the same bill', () {
    final store = PosStore()..add(beer);
    final bill = store.sendCartToTable('Table 1');

    final moved = store.moveOrder(bill.id, 'Table 2');

    expect(moved.id, bill.id);
    expect(store.openOrderFor('Table 1'), isNull);
    expect(store.openOrderFor('Table 2')!.total, 25000);
  });

  test('moving onto an occupied table merges the bills', () {
    final store = PosStore();
    store
      ..add(beer)
      ..add(fries);
    final source = store.sendCartToTable('Table 1');
    store
      ..add(beer)
      ..add(beer);
    final target = store.sendCartToTable('Table 2');

    final merged = store.moveOrder(source.id, 'Table 2');

    expect(merged.id, target.id);
    expect(store.openOrders, hasLength(1));
    expect(store.openOrderFor('Table 1'), isNull);
    expect(merged.total, 25000 * 3 + 35000);
    expect(merged.items.firstWhere((i) => i.name == 'Beer').quantity, 3);
  });
}
