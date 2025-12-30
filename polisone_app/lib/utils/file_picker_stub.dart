
import 'dart:typed_data';

class PlatformFile {
  final String name;
  final Uint8List bytes;
  
  PlatformFile(this.name, this.bytes);
}

abstract class FilePickerHelper {
  Future<PlatformFile?> pickImage();
  Future<PlatformFile?> pickFile(List<String> allowedExtensions);
}

FilePickerHelper getFilePicker() => throw UnsupportedError('Platform not supported');
