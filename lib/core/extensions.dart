import 'dart:io';

extension FileExtension on File {
  Future<void> deleteIfExists() async {
    if (await exists()) await delete();
  }
}