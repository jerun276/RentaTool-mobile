import 'dart:io';
import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  final now = DateTime.now();
  final timestamp = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}";
  final String outDir = 'screenshots/$timestamp';
  
  await Directory(outDir).create(recursive: true);

  try {
    await integrationDriver(
      onScreenshot: (String screenshotName, List<int> screenshotBytes, [Map<String, Object?>? args]) async {
        final File image = await File('$outDir/$screenshotName.png').create(recursive: true);
        image.writeAsBytesSync(screenshotBytes);
        print('✅ Screenshot saved: $outDir/$screenshotName.png');
        return true;
      },
    );
  } catch (e) {
    print('Error running driver: $e');
  }
}

