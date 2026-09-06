import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../services/secure_storage_service.dart';

class ThreatScanResult {
  const ThreatScanResult({
    required this.status,
    required this.kind,
    required this.analysisId,
    required this.stats,
    required this.detections,
    this.resourceId,
    this.filename,
    this.permalink,
  });

  factory ThreatScanResult.fromJson(Map<String, dynamic> json) {
    final rawStats = json['stats'];
    final rawDetections = json['detections'];
    final stats = <String, int>{};
    if (rawStats is Map) {
      for (final entry in rawStats.entries) {
        stats[entry.key.toString()] = int.tryParse('${entry.value}') ?? 0;
      }
    }
    final detections = <ThreatDetection>[];
    if (rawDetections is List) {
      for (final item in rawDetections) {
        if (item is Map) {
          detections
              .add(ThreatDetection.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    return ThreatScanResult(
      status: '${json['status'] ?? 'queued'}',
      kind: '${json['kind'] ?? ''}',
      analysisId: '${json['analysis_id'] ?? ''}',
      resourceId: json['resource_id']?.toString(),
      filename: json['filename']?.toString(),
      permalink: json['permalink']?.toString(),
      stats: stats,
      detections: detections,
    );
  }

  final String status;
  final String kind;
  final String analysisId;
  final String? resourceId;
  final String? filename;
  final String? permalink;
  final Map<String, int> stats;
  final List<ThreatDetection> detections;

  int get malicious => stats['malicious'] ?? 0;
  int get suspicious => stats['suspicious'] ?? 0;
  int get harmless => stats['harmless'] ?? 0;
  int get undetected => stats['undetected'] ?? 0;

  bool get isFinished => status == 'completed';
}

class ThreatDetection {
  const ThreatDetection(
      {required this.engine, required this.category, required this.result});

  factory ThreatDetection.fromJson(Map<String, dynamic> json) =>
      ThreatDetection(
        engine: '${json['engine'] ?? 'Unknown engine'}',
        category: '${json['category'] ?? 'suspicious'}',
        result: '${json['result'] ?? ''}',
      );

  final String engine;
  final String category;
  final String result;
}

class ExploitDbItem {
  const ExploitDbItem({
    required this.id,
    required this.title,
    required this.file,
    required this.date,
    required this.author,
    required this.type,
    required this.platform,
    required this.url,
  });

  factory ExploitDbItem.fromJson(Map<String, dynamic> json) => ExploitDbItem(
        id: '${json['id'] ?? ''}',
        title: '${json['title'] ?? ''}',
        file: '${json['file'] ?? ''}',
        date: '${json['date'] ?? ''}',
        author: '${json['author'] ?? ''}',
        type: '${json['type'] ?? ''}',
        platform: '${json['platform'] ?? ''}',
        url: '${json['url'] ?? ''}',
      );

  final String id;
  final String title;
  final String file;
  final String date;
  final String author;
  final String type;
  final String platform;
  final String url;
}

class ThreatIntelService {
  ThreatIntelService(this._dioClient, this._storage);

  final DioClient _dioClient;
  final SecureStorageService _storage;

  Future<String?> _virusTotalKey() async {
    final key = (await _storage.readVirusTotalKey())?.trim() ?? '';
    // An empty value is valid here: the backend can use its server-side
    // VIRUSTOTAL_API_KEY. This also keeps the key out of the app bundle.
    return key.isEmpty ? null : key;
  }

  Options? _keyOptions(String? key) =>
      key == null ? null : Options(headers: {'X-VirusTotal-API-Key': key});

  Future<ThreatScanResult> scanUrl(String url) async {
    final key = await _virusTotalKey();
    return _withNetworkHandling(() async {
      final response = await _dioClient.dio.post<Map<String, dynamic>>(
        '/api/v1/virustotal/urls',
        data: {'url': url.trim()},
        options: _keyOptions(key),
      );
      return _parseResult(response.data);
    });
  }

  Future<ThreatScanResult> scanFile(Uint8List bytes, String filename,
      {String? mimeType}) async {
    final key = await _virusTotalKey();
    return _withNetworkHandling(() async {
      final form = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: filename,
          contentType: mimeType == null ? null : DioMediaType.parse(mimeType),
        ),
      });
      final response = await _dioClient.dio.post<Map<String, dynamic>>(
        '/api/v1/virustotal/files',
        data: form,
        options: _keyOptions(key),
      );
      return _parseResult(response.data);
    });
  }

  Future<ThreatScanResult> lookupHash(String hash) async {
    final key = await _virusTotalKey();
    return _withNetworkHandling(() async {
      final response = await _dioClient.dio.get<Map<String, dynamic>>(
        '/api/v1/virustotal/files/${hash.trim()}',
        options: _keyOptions(key),
      );
      return _parseResult(response.data);
    });
  }

  Future<ThreatScanResult> refreshAnalysis(ThreatScanResult current) async {
    if (current.analysisId.isEmpty) return current;
    final key = await _virusTotalKey();
    return _withNetworkHandling(() async {
      final response = await _dioClient.dio.get<Map<String, dynamic>>(
        '/api/v1/virustotal/analyses/${current.analysisId}',
        queryParameters: {
          'kind': current.kind,
          if (current.filename != null) 'filename': current.filename,
        },
        options: _keyOptions(key),
      );
      return _parseResult(response.data);
    });
  }

  Future<List<ExploitDbItem>> searchExploitDb(String query) async {
    return _withNetworkHandling(() async {
      final response = await _dioClient.dio.get<Map<String, dynamic>>(
        '/api/v1/exploitdb/search',
        queryParameters: {'q': query.trim(), 'limit': 20},
      );
      final raw = response.data?['results'];
      if (raw is! List) return const <ExploitDbItem>[];
      return raw
          .whereType<Map>()
          .map(
              (item) => ExploitDbItem.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    });
  }

  ThreatScanResult _parseResult(Map<String, dynamic>? data) {
    if (data == null) {
      throw const ParsingException('Empty threat-intelligence response.');
    }
    return ThreatScanResult.fromJson(data);
  }

  Future<T> _withNetworkHandling<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (error) {
      if (error.error is AppException) throw error.error! as AppException;
      throw NetworkException(
          'Threat-intelligence request failed: ${error.message}');
    } on AppException {
      rethrow;
    } catch (error) {
      throw ParsingException(
          'Failed to parse threat-intelligence response: $error');
    }
  }
}
