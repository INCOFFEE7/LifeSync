import 'dart:io';
import 'package:image/image.dart' as img;

void main() async {
  final file = File('assets/images/WhatToDoAppLogo.png');
  if (!await file.exists()) {
    print('WhatToDoAppLogo.png not found');
    return;
  }
  final bytes = await file.readAsBytes();
  final original = img.decodeImage(bytes);
  if (original == null) {
    print('Failed to decode image');
    return;
  }

  // Gunakan kanvas resolusi tinggi (1024x1024) dengan interpolasi cubic agar tidak pecah/blur
  const canvasSize = 1024;
  final canvas = img.Image(width: canvasSize, height: canvasSize);
  img.fill(canvas, color: img.ColorRgb8(255, 255, 255));

  const targetSize = 640;
  final resized = img.copyResize(
    original,
    width: targetSize,
    height: targetSize,
    interpolation: img.Interpolation.cubic,
  );

  final x = (canvasSize - resized.width) ~/ 2;
  final y = (canvasSize - resized.height) ~/ 2;
  img.compositeImage(canvas, resized, dstX: x, dstY: y);

  final outputBytes = img.encodePng(canvas);
  await File('assets/images/WhatToDoAppLogoPadded.png').writeAsBytes(outputBytes);
  print('Successfully created high-res WhatToDoAppLogoPadded.png');
}
