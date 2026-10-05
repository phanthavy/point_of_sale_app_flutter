import 'package:client/main.dart';
import 'package:client/state/auth_store.dart';
import 'package:client/state/pos_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> startApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const MyApp());
}

Future<void> login(
  WidgetTester tester,
  String username,
  String password,
) async {
  await tester.enterText(find.widgetWithText(TextField, 'Username'), username);
  await tester.enterText(find.widgetWithText(TextField, 'Password'), password);
  await tester.tap(find.widgetWithText(FilledButton, 'Login'));
  await tester.pumpAndSettle();
}

Future<void> logout(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Logout'));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(FilledButton, 'Logout'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    posStore.reset();
    authStore.logout();
  });

  testWidgets('wrong password shows an error', (tester) async {
    await startApp(tester);
    await login(tester, 'admin', 'nope');
    expect(find.text('Wrong username or password'), findsOneWidget);
  });

  testWidgets('employee sees Product, Orders, History but not Stats', (
    tester,
  ) async {
    await startApp(tester);
    await login(tester, 'staff', 'staff123');
    for (final tab in ['Product', 'Orders', 'History']) {
      expect(find.text(tab), findsOneWidget);
    }
    expect(find.text('Stats'), findsNothing);
    expect(find.text('Kitchen'), findsNothing);
  });

  testWidgets('employee cannot move, check or print the bill', (tester) async {
    await startApp(tester);
    await login(tester, 'staff', 'staff123');
    await tester.tap(find.byIcon(Icons.add).first);
    await tester.pump();
    await tester.tap(find.text('Orders'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send to table'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Table 4'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Table 4'));
    await tester.pumpAndSettle();
    expect(find.text('UNPAID'), findsOneWidget);
    expect(find.text('Lao beer'), findsWidgets);
    expect(find.text('Move table'), findsNothing);
    expect(
      find.text('Only admin can move the table, check and print the bill.'),
      findsOneWidget,
    );
    expect(find.widgetWithText(FilledButton, 'Cash'), findsNothing);
    expect(find.widgetWithText(FilledButton, 'Transfer'), findsNothing);
    expect(find.text('Print bill'), findsNothing);
  });

  testWidgets('kitchen only sees orders sent from tables', (tester) async {
    await startApp(tester);

    await login(tester, 'staff', 'staff123');
    await tester.tap(find.byIcon(Icons.add).first);
    await tester.pump();
    await tester.tap(find.text('Orders'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send to table'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Table 2'));
    await tester.pumpAndSettle();
    await logout(tester);

    await login(tester, 'kitchen', 'kitchen123');
    expect(find.text('Product'), findsNothing);
    expect(find.text('History'), findsNothing);
    expect(find.text('Table 2'), findsOneWidget);
    expect(find.text('Lao beer'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Done'));
    await tester.pumpAndSettle();
    expect(find.text('No orders to cook'), findsOneWidget);
  });

  testWidgets('send order to a table, add more later, then pay by transfer', (
    tester,
  ) async {
    await startApp(tester);
    await login(tester, 'admin', 'admin123');
    expect(find.text('Stats'), findsOneWidget);
    expect(find.text('Kitchen'), findsOneWidget);

    Future<void> sendToTable3() async {
      await tester.tap(find.text('Send to table'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Table 3'));
      await tester.pumpAndSettle();
    }

    // First round: 2 beers to Table 3.
    await tester.tap(find.byIcon(Icons.add).first);
    await tester.tap(find.byIcon(Icons.add).first);
    await tester.pump();
    await tester.tap(find.text('Orders'));
    await tester.pumpAndSettle();
    await sendToTable3();
    expect(find.text('50,000 ₭'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // Second round: 1 more beer goes onto the same open bill.
    await tester.tap(find.text('Product'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add).first);
    await tester.pump();
    await tester.tap(find.text('Orders'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('New order'));
    await tester.pumpAndSettle();
    await sendToTable3();
    expect(find.text('75,000 ₭'), findsOneWidget);

    // Customer moves from Table 3 to Table 5; the bill goes with them.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Table 3'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Move table'));
    await tester.pumpAndSettle();
    expect(find.text('Move Table 3 to...'), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Table 5'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Move table'), findsNothing);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    // Customer leaves: open the bill and pay by transfer.
    await tester.tap(find.text('Table 5'));
    await tester.pumpAndSettle();
    expect(find.text('UNPAID'), findsOneWidget);
    expect(find.text('75,000 ₭'), findsWidgets);
    expect(find.text('Print bill'), findsNothing);
    await tester.tap(find.widgetWithText(FilledButton, 'Transfer'));
    await tester.pumpAndSettle();
    expect(find.text('Scan to pay'), findsOneWidget);
    expect(find.text('Print bill'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Lao beer'),
      ),
      findsOneWidget,
    );
    expect(find.text('UNPAID'), findsOneWidget);
    await tester.tap(find.text('Payment received'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Tables (0 open)'), findsOneWidget);

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.text('Table 5'), findsOneWidget);
    expect(find.text('75,000 ₭'), findsOneWidget);
    expect(find.text('1 bills'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.calendar_month));
    await tester.pumpAndSettle();
    expect(find.text('Show bills for'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('All days'));
    await tester.pumpAndSettle();
    expect(find.text('Table 5'), findsOneWidget);

    await tester.tap(find.text('Cash'));
    await tester.pumpAndSettle();
    expect(find.text('No bills match this filter'), findsOneWidget);

    await tester.tap(find.text('Stats'));
    await tester.pumpAndSettle();
    expect(find.text('3 sold'), findsOneWidget);
  });
}
