import 'package:client/models/order.dart';
import 'package:client/models/product.dart';
import 'package:client/state/auth_store.dart';
import 'package:client/state/pos_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const beer = Product(id: 1, name: 'Beer', price: 25000, categoryId: 1);
const fries = Product(id: 2, name: 'Fries', price: 35000, categoryId: 2);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('bills, kitchen tickets and cart survive an app restart', () async {
    final prefs = await SharedPreferences.getInstance();

    final before = PosStore()..attach(prefs);
    before
      ..add(beer)
      ..add(beer);
    final paid = before.sendCartToTable('Table 1');
    before.pay(paid.id, PaymentMethod.transfer);
    before.add(fries);
    before.sendCartToTable('Table 2');
    before.markTicketDone(1);
    before.add(beer);

    final after = PosStore()..attach(prefs);

    expect(after.paidOrders.single.table, 'Table 1');
    expect(after.paidOrders.single.paymentMethod, PaymentMethod.transfer);
    expect(after.paidOrders.single.total, 50000);
    expect(after.openOrderFor('Table 2')!.total, 35000);
    expect(after.doneTickets.single.table, 'Table 1');
    expect(after.pendingTickets.single.table, 'Table 2');
    expect(after.cartCount, 1);

    after.sendCartToTable('Table 3');
    expect(after.openOrderFor('Table 3')!.id, 3);
  });

  test('logged-in user is remembered until logout', () async {
    final prefs = await SharedPreferences.getInstance();

    AuthStore()
      ..attach(prefs)
      ..login('staff', 'staff123');
    expect((AuthStore()..attach(prefs)).user?.username, 'staff');

    (AuthStore()..attach(prefs)).logout();
    expect((AuthStore()..attach(prefs)).user, isNull);
  });
}
