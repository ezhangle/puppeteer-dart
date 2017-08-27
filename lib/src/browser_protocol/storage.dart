import 'dart:async';
import 'package:meta/meta.dart' show required;
import '../connection.dart';

class StorageManager {
  final Session _client;

  StorageManager(this._client);

  /// Clears storage for origin.
  /// [origin] Security origin.
  /// [storageTypes] Comma separated origin names.
  Future clearDataForOrigin(
    String origin,
    String storageTypes,
  ) async {
    Map parameters = {
      'origin': origin,
      'storageTypes': storageTypes,
    };
    await _client.send('Storage.clearDataForOrigin', parameters);
  }

  /// Returns usage and quota in bytes.
  /// [origin] Security origin.
  Future<GetUsageAndQuotaResult> getUsageAndQuota(
    String origin,
  ) async {
    Map parameters = {
      'origin': origin,
    };
    await _client.send('Storage.getUsageAndQuota', parameters);
  }
}

class GetUsageAndQuotaResult {
  /// Storage usage (bytes).
  final num usage;

  /// Storage quota (bytes).
  final num quota;

  /// Storage usage per type (bytes).
  final List<UsageForType> usageBreakdown;

  GetUsageAndQuotaResult({
    @required this.usage,
    @required this.quota,
    @required this.usageBreakdown,
  });

  factory GetUsageAndQuotaResult.fromJson(Map json) {
    return new GetUsageAndQuotaResult(
      usage: json['usage'],
      quota: json['quota'],
      usageBreakdown: (json['usageBreakdown'] as List)
          .map((e) => new UsageForType.fromJson(e))
          .toList(),
    );
  }
}

/// Enum of possible storage types.
class StorageType {
  static const StorageType appcache = const StorageType._('appcache');
  static const StorageType cookies = const StorageType._('cookies');
  static const StorageType fileSystems = const StorageType._('file_systems');
  static const StorageType indexeddb = const StorageType._('indexeddb');
  static const StorageType localStorage = const StorageType._('local_storage');
  static const StorageType shaderCache = const StorageType._('shader_cache');
  static const StorageType websql = const StorageType._('websql');
  static const StorageType serviceWorkers =
      const StorageType._('service_workers');
  static const StorageType cacheStorage = const StorageType._('cache_storage');
  static const StorageType all = const StorageType._('all');
  static const StorageType other = const StorageType._('other');
  static const values = const {
    'appcache': appcache,
    'cookies': cookies,
    'file_systems': fileSystems,
    'indexeddb': indexeddb,
    'local_storage': localStorage,
    'shader_cache': shaderCache,
    'websql': websql,
    'service_workers': serviceWorkers,
    'cache_storage': cacheStorage,
    'all': all,
    'other': other,
  };

  final String value;

  const StorageType._(this.value);

  factory StorageType.fromJson(String value) => values[value];

  String toJson() => value;
}

/// Usage for a storage type.
class UsageForType {
  /// Name of storage type.
  final StorageType storageType;

  /// Storage usage (bytes).
  final num usage;

  UsageForType({
    @required this.storageType,
    @required this.usage,
  });

  factory UsageForType.fromJson(Map json) {
    return new UsageForType(
      storageType: new StorageType.fromJson(json['storageType']),
      usage: json['usage'],
    );
  }

  Map toJson() {
    Map json = {
      'storageType': storageType.toJson(),
      'usage': usage,
    };
    return json;
  }
}
