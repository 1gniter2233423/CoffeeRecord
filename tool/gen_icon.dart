import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final image = img.Image(width: 512, height: 512);
  final bg = img.ColorRgba8(139, 94, 60, 255);
  final fg = img.ColorRgba8(255, 255, 255, 255);

  // 填充背景
  for (int y = 0; y < 512; y++) {
    for (int x = 0; x < 512; x++) {
      image.setPixel(x, y, bg);
    }
  }

  // 圆角矩形壶身
  drawRoundRect(image, 120, 160, 390, 430, 20, fg, 6);
  // 壶盖
  drawHLine(image, 120, 390, 158, fg, 4);
  // 盖钮
  drawHLine(image, 215, 295, 138, fg, 8);
  // 壶嘴
  drawCubicBezier(image, 370, 200, 440, 180, 470, 120, 455, 85, fg, 5);
  drawCubicBezier(image, 455, 85, 450, 70, 430, 60, 400, 75, fg, 5);
  // 把手
  drawCubicBezier(image, 125, 430, 30, 410, 20, 230, 40, 155, fg, 6);
  drawCubicBezier(image, 40, 155, 62, 120, 95, 130, 128, 155, fg, 6);
  // 底座
  drawHLine(image, 110, 400, 432, fg, 5);

  File('assets/app_icon.png').createSync(recursive: true);
  File('assets/app_icon.png').writeAsBytesSync(img.encodePng(image));
  print('✅ Icon generated: assets/app_icon.png');
}

void drawRoundRect(img.Image image, int x1, int y1, int x2, int y2, int r, img.Color c, int w) {
  for (int y = y1 + r; y <= y2; y++) {
    for (int x = x1; x <= x2; x++) {
      for (int i = -w ~/ 2; i <= w ~/ 2; i++) {
        for (int j = -w ~/ 2; j <= w ~/ 2; j++) {
          ps(image, x + i, y + j, c);
        }
      }
    }
  }
  for (int dy = -r; dy <= r; dy++) {
    for (int dx = -r; dx <= r; dx++) {
      if (dx * dx + dy * dy <= r * r) {
        for (int i = -w ~/ 2; i <= w ~/ 2; i++) {
          for (int j = -w ~/ 2; j <= w ~/ 2; j++) {
            ps(image, x1 + r + dx + i, y1 + r + dy + j, c);
            ps(image, x2 - r + dx + i, y1 + r + dy + j, c);
            ps(image, x1 + r + dx + i, y2 - r + dy + j, c);
            ps(image, x2 - r + dx + i, y2 - r + dy + j, c);
          }
        }
      }
    }
  }
}

void drawHLine(img.Image image, int x1, int x2, int y, img.Color c, int w) {
  for (int x = x1; x <= x2; x++) {
    for (int i = -w ~/ 2; i <= w ~/ 2; i++) {
      ps(image, x, y + i, c);
    }
  }
}

void drawCubicBezier(img.Image image, int x0, int y0, int x1, int y1, int x2, int y2, int x3, int y3, img.Color c, int w) {
  for (double t = 0; t <= 1; t += 0.002) {
    final mt = 1 - t;
    final x = (mt * mt * mt * x0 + 3 * mt * mt * t * x1 + 3 * mt * t * t * x2 + t * t * t * x3).toInt();
    final y = (mt * mt * mt * y0 + 3 * mt * mt * t * y1 + 3 * mt * t * t * y2 + t * t * t * y3).toInt();
    for (int i = -w ~/ 2; i <= w ~/ 2; i++) {
      for (int j = -w ~/ 2; j <= w ~/ 2; j++) {
        ps(image, x + i, y + j, c);
      }
    }
  }
}

void ps(img.Image image, int x, int y, img.Color c) {
  if (x >= 0 && x < 512 && y >= 0 && y < 512) {
    image.setPixel(x, y, c);
  }
}
