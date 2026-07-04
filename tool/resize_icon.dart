import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final src = img.decodeImage(File('assets/icon_raw.png').readAsBytesSync())!;
  print('Original: ${src.width}x${src.height}');

  // 放在 512x512 正方形画布中央，棕色背景
  final canvas = img.Image(width: 512, height: 512);
  final bg = img.ColorRgba8(139, 94, 60, 255);
  for (int y = 0; y < 512; y++) {
    for (int x = 0; x < 512; x++) {
      canvas.setPixel(x, y, bg);
    }
  }

  // 居中放置原图
  final ox = (512 - src.width) ~/ 2;
  final oy = (512 - src.height) ~/ 2;
  for (int y = 0; y < src.height; y++) {
    for (int x = 0; x < src.width; x++) {
      final px = src.getPixel(x, y);
      canvas.setPixel(ox + x, oy + y, px);
    }
  }

  // 保存
  File('assets/app_icon.png').writeAsBytesSync(img.encodePng(canvas));
  print('✅ assets/app_icon.png (512x512)');

  // 生成各平台尺寸
  final icon192 = img.copyResize(canvas, width: 192, height: 192);
  File('assets/app_icon_192.png').writeAsBytesSync(img.encodePng(icon192));
  print('✅ assets/app_icon_192.png (192x192)');

  final icon512 = img.copyResize(canvas, width: 512, height: 512);
  File('assets/app_icon_512.png').writeAsBytesSync(img.encodePng(icon512));
  print('✅ assets/app_icon_512.png (512x512)');

  // macOS icons
  void saveMac(String name, int size) {
    final img2 = img.copyResize(canvas, width: size, height: size);
    File('macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_$name.png')
        .writeAsBytesSync(img.encodePng(img2));
  }
  saveMac('16', 16); saveMac('32', 32); saveMac('64', 64);
  saveMac('128', 128); saveMac('256', 256);
  saveMac('512', 512); saveMac('1024', 1024);
  print('✅ macOS icons');

  // iOS icons
  void saveIos(String name, int size) {
    final img2 = img.copyResize(canvas, width: size, height: size);
    File('ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-$name.png')
        .writeAsBytesSync(img.encodePng(img2));
  }
  saveIos('20x20@1x', 20); saveIos('20x20@2x', 40); saveIos('20x20@3x', 60);
  saveIos('29x29@1x', 29); saveIos('29x29@2x', 58); saveIos('29x29@3x', 87);
  saveIos('40x40@1x', 40); saveIos('40x40@2x', 80); saveIos('40x40@3x', 120);
  saveIos('50x50@1x', 50); saveIos('50x50@2x', 100);
  saveIos('57x57@1x', 57); saveIos('57x57@2x', 114);
  saveIos('60x60@2x', 120); saveIos('60x60@3x', 180);
  saveIos('72x72@1x', 72); saveIos('72x72@2x', 144);
  saveIos('76x76@1x', 76); saveIos('76x76@2x', 152);
  saveIos('83.5x83.5@2x', 167);
  saveIos('1024x1024@1x', 1024);
  print('✅ iOS icons');

  // Android mipmap
  void saveAndroid(String name, int size) {
    final img2 = img.copyResize(canvas, width: size, height: size);
    File('android/app/src/main/res/mipmap-$name/ic_launcher.png')
        .writeAsBytesSync(img.encodePng(img2));
  }
  saveAndroid('hdpi', 72);
  saveAndroid('mdpi', 48);
  saveAndroid('xhdpi', 96);
  saveAndroid('xxhdpi', 144);
  saveAndroid('xxxhdpi', 192);
  print('✅ Android mipmap icons');

  // Web favicon
  final favicon = img.copyResize(canvas, width: 64, height: 64);
  File('web/favicon.png').writeAsBytesSync(img.encodePng(favicon));
  print('✅ web/favicon.png');

  // Windows icon
  final win32 = img.copyResize(canvas, width: 256, height: 256);
  File('assets/app_icon_256.png').writeAsBytesSync(img.encodePng(win32));
  print('✅ assets/app_icon_256.png');

  // Cleanup
  File('assets/icon_raw.png').deleteSync();
  print('🧹清理临时文件');
  print('🎉 全部完成!');
}
