import 'package:client/models/order.dart';

// Demo bank details, not a real account.
const bankName = 'LAO DEMO BANK';
const bankAccountName = 'BOBBY RESTAURANT';
const bankAccountNumber = '010-12-00-01234567-001';

String transferQrData(Order order) =>
    'DEMO-PAY|$bankAccountNumber|BILL-${order.id}|${order.total}LAK';
