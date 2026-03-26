import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/constants.dart';

/// Manages downloading the Gemma 3 1B model file to permanent local storage.
///
/// Downloads are resumable: a partial `.part` file is preserved across app
/// restarts and the next call uses an HTTP Range header to continue from
/// where it left off.
class ModelDownloadManager {
  final Dio _dio;

  ModelDownloadManager({Dio? dio}) : _dio = dio ?? Dio();

  /// Absolute path to the fully-written model file.
  static Future<String> modelPath() async {
    final dir = await getApplicationSupportDirectory();
    return '${dir.path}/${AppConstants.gemmaModelFilename}';
  }

  /// Returns true when the model file is present and large enough to be valid
  /// (> 400 MB). Guards against partially-written files from earlier crashes.
  static Future<bool> isModelReady() async {
    final path = await modelPath();
    final file = File(path);
    if (!await file.exists()) {
      return false;
    }
    return await file.length() > 400 * 1024 * 1024;
  }

  /// Returns true when a partial download is already in progress on disk.
  ///
  /// A `.part` file with at least 10 MB written indicates the user has already
  /// seen and accepted the consent dialog during a previous session. The create
  /// flow uses this to auto-resume the download silently rather than showing
  /// the consent dialog again.
  ///
  /// The 10 MB threshold filters out empty or nearly-empty `.part` files that
  /// could have been created by a failed connection attempt before any bytes
  /// were transferred.
  static Future<bool> hasPartialDownload() async {
    final path = await modelPath();
    final partFile = File('$path.part');
    if (!await partFile.exists()) {
      return false;
    }
    return await partFile.length() > 10 * 1024 * 1024;
  }

  /// Downloads the model, yielding progress in [0.0, 1.0].
  ///
  /// Data accumulates in a `.part` file and is renamed atomically to the
  /// final path on completion, so [isModelReady] never returns true for a
  /// partial download.
  Stream<double> download() async* {
    final path = await modelPath();
    final tempPath = '$path.part';
    final sourcePath = '$path.part.source';
    final tempFile = File(tempPath);
    final sourceFile = File(sourcePath);

    final existingBytes = await tempFile.exists() ? await tempFile.length() : 0;
    final pinnedUrl = await sourceFile.exists() ? (await sourceFile.readAsString()).trim() : null;

    final candidateUrls = <String>[
      if (pinnedUrl != null && pinnedUrl.isNotEmpty) pinnedUrl,
      ...AppConstants.gemmaModelUrls.where((url) => url != pinnedUrl),
    ];

    IOSink? sink;
    try {
      final response = await _openDownloadStream(
        urls: candidateUrls,
        existingBytes: existingBytes,
        allowFallback: existingBytes == 0,
      );

      await sourceFile.writeAsString(response.$1, flush: true);

      final contentLength = int.tryParse(response.$2.headers.value('content-length') ?? '');
      final totalBytes = contentLength != null ? existingBytes + contentLength : null;

      sink = tempFile.openWrite(mode: FileMode.append);
      var receivedBytes = existingBytes;

      await for (final chunk in response.$2.data!.stream) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (totalBytes != null && totalBytes > 0) {
          yield receivedBytes / totalBytes;
        }
      }

      await sink.flush();
      await sink.close();
      sink = null;

      await tempFile.rename(path);
      if (await sourceFile.exists()) {
        await sourceFile.delete();
      }
      yield 1.0;
    } catch (e) {
      debugPrint('ModelDownloadManager: interrupted — $e');
      rethrow;
    } finally {
      await sink?.close();
    }
  }

  Future<(String, Response<ResponseBody>)> _openDownloadStream({
    required List<String> urls,
    required int existingBytes,
    required bool allowFallback,
  }) async {
    Object? lastError;

    for (int i = 0; i < urls.length; i++) {
      final url = urls[i];
      final headers = <String, String>{
        'Accept': 'application/octet-stream',
        'User-Agent': 'Threadcast/1.0 (mobile; +https://github.com/threadcast)',
      };
      if (existingBytes > 0) {
        headers['Range'] = 'bytes=$existingBytes-';
      }

      try {
        final response = await _dio.get<ResponseBody>(
          url,
          options: Options(
            responseType: ResponseType.stream,
            followRedirects: true,
            headers: headers,
            validateStatus: (status) => status != null && status >= 200 && status < 400,
          ),
        );
        return (url, response);
      } on DioException catch (e) {
        lastError = e;
        final code = e.response?.statusCode;
        final canTryNext = allowFallback && i < urls.length - 1;
        final isAuthLikeError = code == 401 || code == 403 || code == 404;

        if (canTryNext && isAuthLikeError) {
          debugPrint('ModelDownloadManager: $code for $url, trying fallback URL');
          continue;
        }
        rethrow;
      } catch (e) {
        lastError = e;
        if (allowFallback && i < urls.length - 1) {
          continue;
        }
        rethrow;
      }
    }

    throw Exception('Unable to open model download stream: $lastError');
  }
}
