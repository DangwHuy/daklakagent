import 'package:flutter/material.dart';

/// CustomPainter vẽ đường nối giữa comment cha và comment con (reply thread line)
class ThreadPainter extends CustomPainter {
  final bool isLastReply;

  ThreadPainter({this.isLastReply = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Đường dọc từ trên xuống
    final double stopY = isLastReply ? size.height / 2 : size.height;
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, stopY),
      paint,
    );

    // Đường ngang sang phải (nối vào avatar reply)
    canvas.drawLine(
      Offset(size.width / 2, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant ThreadPainter oldDelegate) {
    return oldDelegate.isLastReply != isLastReply;
  }
}
