import 'package:barcode/barcode.dart';
import 'package:flutter/material.dart';

/// A QR code for demo payment data. It scans, but no bank app will accept it.
class FakeQrCode extends StatelessWidget {
  final String data;
  final double size;

  const FakeQrCode({super.key, required this.data, this.size = 200});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size.square(size), painter: _QrPainter(data));
  }
}

class _QrPainter extends CustomPainter {
  final String data;

  _QrPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    final black = Paint()..color = Colors.black;
    final elements = Barcode.qrCode().make(
      data,
      width: size.width,
      height: size.height,
    );
    for (final element in elements) {
      if (element is BarcodeBar && element.black) {
        canvas.drawRect(
          Rect.fromLTWH(
            element.left,
            element.top,
            element.width + 0.5,
            element.height + 0.5,
          ),
          black,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_QrPainter oldDelegate) => oldDelegate.data != data;
}
