import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class TtsModelExtractor {
  static const _currentVersion = '3';
  static const _assetRoot = 'assets/tts_models/';

  static Future<String>? _ensureExtractedFuture;
  static String? _cachedModelDirPath;

  static Future<String> ensureExtracted() {
    // 1. Check in-memory cache (exists only during this app session)
    if (_cachedModelDirPath != null) {
      return Future.value(_cachedModelDirPath!);
    }

    // Use a future variable to prevent multiple simultaneous extraction attempts
    return _ensureExtractedFuture ??= _extractIfNeeded();
  }

  static Future<String> _extractIfNeeded() async {
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final modelDir = Directory('${docsDir.path}/tts_models');
      final versionFile = File('${modelDir.path}/.version');

      // 2. Check Disk Cache (persists after app restart)
      if (await versionFile.exists()) {
        final existingVersion = (await versionFile.readAsString()).trim();
        if (existingVersion == _currentVersion) {
          _cachedModelDirPath = modelDir.path;
          return modelDir.path;
        }
      }

      // 3. Actual Extraction (only runs if disk cache is missing or outdated)
      if (await modelDir.exists()) {
        await modelDir.delete(recursive: true);
      }
      await modelDir.create(recursive: true);

      final assetManifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final assets = assetManifest.listAssets().where((key) => key.startsWith(_assetRoot)).toList()..sort();

      for (final assetPath in assets) {
        final relativePath = assetPath.replaceFirst(_assetRoot, '');
        if (relativePath.isEmpty) continue;

        final outFile = File('${modelDir.path}/$relativePath');
        await outFile.parent.create(recursive: true);

        final data = await rootBundle.load(assetPath);
        await outFile.writeAsBytes(data.buffer.asUint8List(), flush: true);
      }

      await versionFile.writeAsString(_currentVersion, flush: true);

      _cachedModelDirPath = modelDir.path;
      return modelDir.path;
    } catch (e) {
      _ensureExtractedFuture = null; // Allow retry on failure
      rethrow;
    }
  }
}
