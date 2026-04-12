import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/app_config.dart';
import '../../core/config/app_environment.dart';
import '../../core/logging/app_logger.dart';
import 'analytics_schema_validator.dart';
import 'analytics_tracker.dart';

class QueuedAnalyticsTracker implements AnalyticsTracker {
  QueuedAnalyticsTracker({
    required AppConfig appConfig,
    required AppLogger logger,
    AnalyticsSchemaValidator? schemaValidator,
    http.Client? httpClient,
    DateTime Function()? nowUtcProvider,
    int maxQueueSize = 250,
    int batchSize = 25,
  })  : _appConfig = appConfig,
        _logger = logger,
        _schemaValidator = schemaValidator ?? const AnalyticsSchemaValidator(),
        _httpClient = httpClient ?? http.Client(),
        _nowUtc = nowUtcProvider ?? (() => DateTime.now().toUtc()),
        _maxQueueSize = maxQueueSize,
        _batchSize = batchSize;

  static const String _storageKey = 'analytics_queue_v1';

  final AppConfig _appConfig;
  final AppLogger _logger;
  final AnalyticsSchemaValidator _schemaValidator;
  final http.Client _httpClient;
  final DateTime Function() _nowUtc;
  final int _maxQueueSize;
  final int _batchSize;

  SharedPreferences? _preferences;
  bool _queueHydrated = false;
  bool _flushInProgress = false;
  int _sequence = 0;
  final List<_QueuedAnalyticsEvent> _queue = <_QueuedAnalyticsEvent>[];

  @override
  Future<void> track(
    String eventName, {
    Map<String, Object?> params = const <String, Object?>{},
  }) async {
    await _hydrateQueueIfNeeded();

    final Map<String, Object?> payload = Map<String, Object?>.from(params);
    payload.putIfAbsent('schema_version', () => _schemaValidator.schemaVersion);
    payload.putIfAbsent(
      'event_ts_utc',
      () => _nowUtc().toIso8601String(),
    );

    final AnalyticsValidationResult validation = _schemaValidator.validate(
      eventName,
      params: payload,
    );

    if (validation.warnings.isNotEmpty) {
      _logger.warn(
        'Analytics warnings for "$eventName": ${validation.warnings.join(' | ')}',
      );
    }

    if (!validation.isValid) {
      _logger.error(
        '[ANALYTICS][QUARANTINE] $eventName '
        'missing=${validation.missingRequired.join(',')}',
      );
      return;
    }

    _sequence += 1;
    _queue.add(
      _QueuedAnalyticsEvent(
        id: 'evt_${_sequence}_${_nowUtc().millisecondsSinceEpoch}',
        eventName: eventName,
        params: payload,
        createdAtUtc: _nowUtc(),
        deliveryAttempts: 0,
      ),
    );
    _trimQueue();
    await _persistQueue();

    if (_shouldAutoFlush(eventName: eventName)) {
      await flush();
    }
  }

  @override
  Future<void> flush({
    bool force = false,
  }) async {
    await _hydrateQueueIfNeeded();
    if (_flushInProgress || _queue.isEmpty) {
      return;
    }
    if (!_appConfig.hasAnalyticsApi) {
      if (force) {
        _logger.warn(
          'Analytics flush requested without configured endpoint. '
          'Queue retained locally (${_queue.length} events).',
        );
      }
      return;
    }

    _flushInProgress = true;
    try {
      final int sendCount =
          force ? _queue.length : _queue.length.clamp(0, _batchSize);
      final List<_QueuedAnalyticsEvent> batch = _queue.take(sendCount).toList();
      final Uri uri = Uri.parse(
        '${_appConfig.analyticsApiBaseUrl}/v1/events/batch',
      );
      final http.Response response = await _httpClient.post(
        uri,
        headers: const <String, String>{
          'content-type': 'application/json',
        },
        body: jsonEncode(
          <String, Object?>{
            'app_name': _appConfig.appName,
            'environment': _appConfig.environment.wireName,
            'app_version': _appConfig.appVersion,
            'events': batch.map((item) => item.toJson()).toList(growable: false),
          },
        ),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _queue.removeRange(0, batch.length);
        await _persistQueue();
        return;
      }

      for (final _QueuedAnalyticsEvent event in batch) {
        event.deliveryAttempts += 1;
      }
      await _persistQueue();
      _logger.warn(
        'Analytics batch flush failed with ${response.statusCode}. '
        'Queue retained (${_queue.length} events).',
      );
    } catch (error) {
      for (final _QueuedAnalyticsEvent event in _queue) {
        event.deliveryAttempts += 1;
      }
      await _persistQueue();
      _logger.warn('Analytics flush threw $error');
    } finally {
      _flushInProgress = false;
    }
  }

  @override
  Future<void> close() async {
    await flush(force: true);
    _httpClient.close();
  }

  bool _shouldAutoFlush({
    required String eventName,
  }) {
    if (_queue.length >= _batchSize) {
      return true;
    }
    return eventName == 'session_end' ||
        eventName == 'ops_session_snapshot' ||
        eventName == 'ops_alert_triggered' ||
        eventName == 'ops_error';
  }

  Future<SharedPreferences> _prefs() async {
    final SharedPreferences? cached = _preferences;
    if (cached != null) {
      return cached;
    }
    final SharedPreferences created = await SharedPreferences.getInstance();
    _preferences = created;
    return created;
  }

  Future<void> _hydrateQueueIfNeeded() async {
    if (_queueHydrated) {
      return;
    }
    _queueHydrated = true;

    final SharedPreferences preferences = await _prefs();
    final List<String> rawQueue =
        preferences.getStringList(_storageKey) ?? const <String>[];
    for (final String rawItem in rawQueue) {
      try {
        _queue.add(_QueuedAnalyticsEvent.fromJsonString(rawItem));
      } catch (error) {
        _logger.warn('Skipping broken analytics queue item: $error');
      }
    }
    if (_queue.isNotEmpty) {
      _sequence = _queue.length;
    }
  }

  Future<void> _persistQueue() async {
    final SharedPreferences preferences = await _prefs();
    await preferences.setStringList(
      _storageKey,
      _queue.map((item) => item.toJsonString()).toList(growable: false),
    );
  }

  void _trimQueue() {
    if (_queue.length <= _maxQueueSize) {
      return;
    }
    _queue.removeRange(0, _queue.length - _maxQueueSize);
  }
}

class _QueuedAnalyticsEvent {
  _QueuedAnalyticsEvent({
    required this.id,
    required this.eventName,
    required this.params,
    required this.createdAtUtc,
    required this.deliveryAttempts,
  });

  final String id;
  final String eventName;
  final Map<String, Object?> params;
  final DateTime createdAtUtc;
  int deliveryAttempts;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'event_name': eventName,
      'params': params,
      'created_at_utc': createdAtUtc.toIso8601String(),
      'delivery_attempts': deliveryAttempts,
    };
  }

  String toJsonString() => jsonEncode(toJson());

  factory _QueuedAnalyticsEvent.fromJsonString(String rawJson) {
    final Object? decoded = jsonDecode(rawJson);
    if (decoded is! Map) {
      throw const FormatException('Queued analytics event must be an object.');
    }
    final Map<String, Object?> json = decoded.cast<String, Object?>();
    final Object? rawParams = json['params'];
    final Map<String, Object?> castParams;
    if (rawParams is Map<String, Object?>) {
      castParams = rawParams;
    } else if (rawParams is Map) {
      castParams = rawParams.cast<String, Object?>();
    } else {
      castParams = const <String, Object?>{};
    }

    return _QueuedAnalyticsEvent(
      id: (json['id'] as String?) ?? 'evt_unknown',
      eventName: (json['event_name'] as String?) ?? 'unknown_event',
      params: castParams,
      createdAtUtc: DateTime.tryParse(
            json['created_at_utc'] as String? ?? '',
          )?.toUtc() ??
          DateTime.utc(1970, 1, 1),
      deliveryAttempts: _readInt(json['delivery_attempts'], fallback: 0),
    );
  }

  static int _readInt(
    Object? rawValue, {
    required int fallback,
  }) {
    if (rawValue is int) {
      return rawValue;
    }
    if (rawValue is num) {
      return rawValue.toInt();
    }
    if (rawValue is String) {
      return int.tryParse(rawValue) ?? fallback;
    }
    return fallback;
  }
}
