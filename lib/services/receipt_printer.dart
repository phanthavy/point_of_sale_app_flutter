import 'dart:typed_data';

import 'package:client/data/bank_info.dart';
import 'package:client/models/order.dart';
import 'package:client/utils/format.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

const _restaurantName = 'BOBBY RESTAURANT';

// The default PDF font has no ₭ glyph, so receipts use "LAK".
String _lak(int amount) => '${formatNumber(amount)} LAK';

/// Builds an 80 mm thermal-roll receipt. Unpaid bills print as "BILL" with a
/// transfer QR at the bottom; paid bills print as "RECEIPT".
Future<Uint8List> buildReceiptPdf(Order order, {required String staffName}) {
  final doc = pw.Document();
  const small = pw.TextStyle(fontSize: 8);
  final dashed = pw.Divider(
    borderStyle: pw.BorderStyle.dashed,
    thickness: 0.5,
    height: 10,
  );

  pw.Widget row(String left, String right, {pw.TextStyle? style}) => pw.Row(
    children: [
      pw.Expanded(child: pw.Text(left, style: style)),
      pw.Text(right, style: style),
    ],
  );

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.roll80,
      margin: const pw.EdgeInsets.all(12),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Text(
            _restaurantName,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            order.isPaid ? 'RECEIPT' : 'BILL',
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
          dashed,
          row(order.table, 'Bill #${order.id}', style: small),
          row('Opened', formatDateTime(order.createdAt), style: small),
          row('Printed', formatDateTime(DateTime.now()), style: small),
          row('Staff', staffName, style: small),
          dashed,
          for (final item in order.items)
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 2),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  row(
                    '${item.quantity} x ${item.name}',
                    _lak(item.subtotal),
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                  pw.Text('   @ ${_lak(item.price)}', style: small),
                ],
              ),
            ),
          dashed,
          row(
            'TOTAL',
            _lak(order.total),
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          if (order.isPaid) ...[
            pw.SizedBox(height: 4),
            row('Paid by', order.paymentMethod!.label, style: small),
            row('Paid at', formatDateTime(order.paidAt!), style: small),
          ] else ...[
            dashed,
            pw.Text(
              'SCAN TO PAY BY TRANSFER',
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            pw.Center(
              child: pw.BarcodeWidget(
                barcode: pw.Barcode.qrCode(),
                data: transferQrData(order),
                width: 110,
                height: 110,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              '$bankName\n$bankAccountName\n$bankAccountNumber',
              textAlign: pw.TextAlign.center,
              style: small,
            ),
            pw.Text(
              'Demo QR only, not a real bank account',
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(fontSize: 7),
            ),
          ],
          dashed,
          pw.Text(
            'Thank you! Please come again.',
            textAlign: pw.TextAlign.center,
            style: small,
          ),
        ],
      ),
    ),
  );
  return doc.save();
}

/// Opens the system print dialog (Wi-Fi printer, or "Save as PDF").
Future<void> printReceipt(Order order, {required String staffName}) {
  return Printing.layoutPdf(
    name: 'Bill-${order.id}-${order.table}',
    format: PdfPageFormat.roll80,
    onLayout: (_) => buildReceiptPdf(order, staffName: staffName),
  );
}
