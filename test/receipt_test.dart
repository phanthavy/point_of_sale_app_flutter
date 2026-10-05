import 'package:client/models/order.dart';
import 'package:client/services/receipt_printer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final order = Order(
    id: 7,
    table: 'Table 3',
    createdAt: DateTime(2026, 10, 5, 12, 30),
    items: const [
      OrderItem(productId: 1, name: 'Lao beer', price: 25000, quantity: 3),
      OrderItem(
        productId: 6,
        name: 'Grilled chicken',
        price: 60000,
        quantity: 1,
      ),
    ],
  );

  test('builds a PDF for an unpaid bill and a paid receipt', () async {
    final bill = await buildReceiptPdf(order, staffName: 'Bobby');
    final receipt = await buildReceiptPdf(
      order.copyWith(
        paymentMethod: PaymentMethod.cash,
        paidAt: DateTime(2026, 10, 5, 13, 45),
      ),
      staffName: 'Bobby',
    );

    for (final pdf in [bill, receipt]) {
      expect(String.fromCharCodes(pdf.take(5)), '%PDF-');
      expect(pdf.length, greaterThan(1000));
    }
    // Only the unpaid bill carries the transfer QR section.
    expect(bill.length, greaterThan(receipt.length + 500));
  });
}
