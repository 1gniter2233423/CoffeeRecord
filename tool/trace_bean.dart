import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final bytes = File(r'C:\Users\14746\Desktop\c19639d01260b6bf7c56e316200a20ffebb6707e331d-gtSr8n_fw658.webp').readAsBytesSync();
  final src = img.decodeImage(bytes)!;
  print('Size: ${src.width}x${src.height}');

  // 缩小到64x64以便处理
  final small = img.copyResize(src, width: 64, height: 64);

  // 转为灰度并找到轮廓
  // 扫描每一行，找到左右边界
  final int threshold = 128;
  int minX = 64, maxX = 0, minY = 64, maxY = 0;

  for (int y = 0; y < small.height; y++) {
    for (int x = 0; x < small.width; x++) {
      final px = small.getPixel(x, y);
      final r = px.r as int;
      final g = px.g as int;
      final b = px.b as int;
      final brightness = (r + g + b) ~/ 3;
      if (brightness < threshold) {
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
    }
  }

  print('Bounds: ($minX,$minY) to ($maxX,$maxY)');
  final cx = (minX + maxX) / 2;
  final cy = (minY + maxY) / 2;
  final bw = (maxX - minX);
  final bh = (maxY - minY);
  print('Center: ($cx, $cy), Size: ${bw}x$bh');

  // 输出每个水平切片上的轮廓点
  final List<List<int>> topEdge = [];
  final List<List<int>> bottomEdge = [];

  for (int y = minY; y <= maxY; y++) {
    int? leftX, rightX;
    for (int x = minX; x <= maxX; x++) {
      final px = small.getPixel(x, y);
      final b = ((px.r as int) + (px.g as int) + (px.b as int)) ~/ 3;
      if (b < threshold && leftX == null) {
        leftX = x;
      }
      if (b < threshold) {
        rightX = x;
      }
    }
    if (leftX != null && rightX != null) {
      topEdge.add([leftX, y]);
      bottomEdge.add([rightX, y]);
    }
  }

  // 输出关键路径点（简化版）
  print('\n=== 顶部轮廓（每隔3个点取一个）===');
  for (int i = 0; i < topEdge.length; i += 3) {
    final x = (topEdge[i][0] - minX) / bw;
    final y = (topEdge[i][1] - minY) / bh;
    print('  ($x, $y),');
  }
  print('\n=== 底部轮廓（每隔3个点取一个）===');
  for (int i = bottomEdge.length - 1; i >= 0; i -= 3) {
    final x = (bottomEdge[i][0] - minX) / bw;
    final y = (bottomEdge[i][1] - minY) / bh;
    print('  ($x, $y),');
  }

  // 输出归一化后的路径点 (用于 CustomPainter)
  print('\n=== 归一化轮廓点 ===');
  final allPoints = <List<double>>[];
  for (int i = 0; i < topEdge.length; i++) {
    allPoints.add([
      (topEdge[i][0] - minX) / bw,
      (topEdge[i][1] - minY) / bh,
    ]);
  }
  for (int i = bottomEdge.length - 1; i >= 0; i--) {
    allPoints.add([
      (bottomEdge[i][0] - minX) / bw,
      (bottomEdge[i][1] - minY) / bh,
    ]);
  }

  // 每隔 2 个点取一个，简化
  print('  final path = Path();');
  for (int i = 0; i < allPoints.length; i += 2) {
    final x = allPoints[i][0].toStringAsFixed(3);
    final y = allPoints[i][1].toStringAsFixed(3);
    if (i == 0) {
      print("  path.moveTo(w * $x, h * $y);");
    } else {
      print("  path.lineTo(w * $x, h * $y);");
    }
  }
  print('  path.close();');
}
