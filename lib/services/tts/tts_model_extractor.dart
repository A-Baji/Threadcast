import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class TtsModelExtractor {
  static const _currentVersion = '1';
  static const _assetRoot = 'assets/tts_models/';

  static Future<String> ensureExtracted() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final modelDir = Directory('${docsDir.path}/tts_models');
    final versionFile = File('${modelDir.path}/.version');

    if (await versionFile.exists() && await versionFile.readAsString() == _currentVersion) {
      return modelDir.path;
    }

    if (await modelDir.exists()) {
      await modelDir.delete(recursive: true);
    }
    await modelDir.create(recursive: true);

    final manifestJson = await rootBundle.loadString('AssetManifest.json');
    final manifest = json.decode(manifestJson) as Map<String, dynamic>;
    final assets = manifest.keys.where((key) => key.startsWith(_assetRoot)).toList()..sort();

    for (final assetPath in assets) {
      final relativePath = assetPath.replaceFirst(_assetRoot, '');
      if (relativePath.isEmpty) {
        continue;
      }

      final outFile = File('${modelDir.path}/$relativePath');
      await outFile.parent.create(recursive: true);
      final data = await rootBundle.load(assetPath);
      await outFile.writeAsBytes(data.buffer.asUint8List(), flush: true);
    }

    await versionFile.writeAsString(_currentVersion, flush: true);
    return modelDir.path;
  }
}
