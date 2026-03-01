import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;

class FlutterDownloader {
  final StreamController<dynamic> _progressController = StreamController<dynamic>.broadcast();
  Stream<dynamic> get onProgress => _progressController.stream;

  Future<Map<String, dynamic>> downloadModel(
    Map<String, dynamic> params,
  ) async {
    final url = params['url'] as String;
    final localPath = params['localPath'] as String;
    final username = params['username'] as String?;
    final password = params['password'] as String?;
    final headers = params['headers'] as Map<String, String>?;

    try {
      final request = http.Request('GET', Uri.parse(url));

      if (username != null && password != null) {
        final auth = '$username:$password';
        final encodedAuth = base64.encode(auth.codeUnits);
        request.headers['Authorization'] = 'Basic $encodedAuth';
      }

      if (headers != null) {
        request.headers.addAll(headers);
      }

      final response = await request.send();

      if (response.statusCode != 200) {
        return {
          'success': false,
          'localPath': localPath,
          'errorMessage':
              'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        };
      }

      final contentLength = response.contentLength ?? -1;
      var bytesReceived = 0;

      final file = File(localPath);
      final sink = file.openWrite();

      await for (final chunk in response.stream) {
        bytesReceived += chunk.length;
        sink.add(chunk);

        if (contentLength > 0) {
          final progress = min(1.0, bytesReceived / contentLength);
          _progressController.add({'progress': progress});
        }
      }

      await sink.close();

      _progressController.add({'progress': 1.0});

      return {'success': true, 'localPath': localPath, 'errorMessage': null};
    } catch (e) {
      return {
        'success': false,
        'localPath': localPath,
        'errorMessage': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> downloadHfFile(
    Map<String, dynamic> params,
  ) async {
    final repoId = params['repoId'] as String;
    final filename = params['filename'] as String;
    final localPath = params['localPath'] as String;
    final bearerToken = params['bearerToken'] as String?;
    final offline = params['offline'] as bool? ?? false;

    if (offline) {
      return {
        'success': false,
        'localPath': localPath,
        'errorMessage': 'Offline mode not supported in Flutter implementation',
      };
    }

    final url = 'https://huggingface.co/$repoId/resolve/main/$filename';

    final headers = <String, String>{};
    if (bearerToken != null) {
      headers['Authorization'] = 'Bearer $bearerToken';
    }

    return downloadModel({
      'url': url,
      'localPath': localPath,
      'headers': headers,
    });
  }

  Future<Map<String, dynamic>> downloadModelAsync(Map<String, dynamic> params) {
    return downloadModel(params);
  }

  Future<Map<String, dynamic>> downloadHfFileAsync(
    Map<String, dynamic> params,
  ) {
    return downloadHfFile(params);
  }

  void dispose() {
    _progressController.close();
  }
}
