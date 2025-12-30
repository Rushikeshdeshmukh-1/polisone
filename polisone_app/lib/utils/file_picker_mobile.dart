
import 'dart:io';
import 'file_picker_stub.dart';

FilePickerHelper getFilePicker() => FilePickerMobile();

class FilePickerMobile implements FilePickerHelper {
  @override
  Future<PlatformFile?> pickImage() async {
    // Stub implementation - would use image_picker
    return null;
  }

  @override
  Future<PlatformFile?> pickFile(List<String> allowedExtensions) async {
    // Stub implementation - would use file_picker
    return null;
  }
}
