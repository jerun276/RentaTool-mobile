import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class LocalProfilePhotoService {
  final ImagePicker _picker;

  LocalProfilePhotoService({ImagePicker? picker})
      : _picker = picker ?? ImagePicker();

  Future<String?> chooseAndSave() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
      maxHeight: 1200,
    );
    if (image == null) return null;

    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory('${documents.path}/profile_photos');
    await directory.create(recursive: true);
    final extension = image.path.contains('.')
        ? image.path.substring(image.path.lastIndexOf('.'))
        : '.jpg';
    final destination =
        '${directory.path}/profile_${DateTime.now().microsecondsSinceEpoch}$extension';
    return (await File(image.path).copy(destination)).path;
  }
}
