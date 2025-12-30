
import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';
import 'file_picker_stub.dart';

class FilePickerWeb implements FilePickerHelper {
  @override
  Future<PlatformFile?> pickImage() async {
    return _pickFile('image/*');
  }

  @override
  Future<PlatformFile?> pickFile(List<String> allowedExtensions) async {
    final accept = allowedExtensions.join(',');
    return _pickFile(accept);
  }

  Future<PlatformFile?> _pickFile(String accept) {
    final completer = Completer<PlatformFile?>();
    final input = html.FileUploadInputElement()..accept = accept;
    input.click();

    input.onChange.listen((e) {
      final files = input.files;
      if (files!.isEmpty) {
        completer.complete(null);
        return;
      }
      final file = files[0];
      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      reader.onLoadEnd.listen((e) {
        completer.complete(PlatformFile(file.name, reader.result as Uint8List));
      });
      reader.onError.listen((e) {
        completer.complete(null);
      });
    });
    
    return completer.future;
  }
}

FilePickerHelper getFilePicker() => FilePickerWeb();
