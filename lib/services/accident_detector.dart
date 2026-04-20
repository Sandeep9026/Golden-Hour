import 'dart:async';
import 'dart:math';

import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';

enum AccidentSeverity { low, medium, high }

extension AccidentSeverityLabel on AccidentSeverity {
  String get label => switch (this) {
        AccidentSeverity.low => 'Low',
        AccidentSeverity.medium => 'Medium',
        AccidentSeverity.high => 'High',
      };
}

class AccidentDetectionResult {
  const AccidentDetectionResult({
    required this.detected,
    required this.severity,
    required this.gForce,
    required this.confidence,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  final bool detected;
  final AccidentSeverity severity;
  final double gForce;
  final double confidence;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
}

class AccidentDetectorService {
  AccidentDetectorService({
    GeolocatorPlatform? geolocator,
  }) : _geolocator = geolocator ?? GeolocatorPlatform.instance;

  final GeolocatorPlatform _geolocator;
  StreamSubscription<AccelerometerEvent>? _subscription;

  static const _gravity = 9.81;

  Future<void> initializeModel() async {}

  Future<bool> ensurePermissions() async {
    final permission = await _geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      final requested = await _geolocator.requestPermission();
      return requested == LocationPermission.always ||
          requested == LocationPermission.whileInUse;
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Stream<AccidentDetectionResult> watchForAccident() async* {
    await initializeModel();
    final hasPermission = await ensurePermissions();
    if (!hasPermission) {
      throw Exception('Location permission is required for accident alerts.');
    }

    final controller = StreamController<AccidentDetectionResult>();

    _subscription = accelerometerEventStream().listen((event) async {
      final gForce = sqrt(
        pow(event.x / _gravity, 2) +
            pow(event.y / _gravity, 2) +
            pow(event.z / _gravity, 2),
      );

      if (gForce < 2.7) {
        return;
      }

      final location = await _geolocator.getCurrentPosition();
      final confidence = _runInference(gForce);
      final severity = _mapSeverity(gForce, confidence);

      controller.add(
        AccidentDetectionResult(
          detected: true,
          severity: severity,
          gForce: gForce,
          confidence: confidence,
          latitude: location.latitude,
          longitude: location.longitude,
          timestamp: DateTime.now(),
        ),
      );
    });

    controller.onCancel = () async {
      await _subscription?.cancel();
    };

    yield* controller.stream;
  }

  AccidentDetectionResult buildManualTrigger(Position position) {
    const gForce = 3.2;
    const confidence = 0.82;
    return AccidentDetectionResult(
      detected: true,
      severity: AccidentSeverity.high,
      gForce: gForce,
      confidence: confidence,
      latitude: position.latitude,
      longitude: position.longitude,
      timestamp: DateTime.now(),
    );
  }

  double _runInference(double gForce) {
    return (gForce / 5).clamp(0.45, 0.96);
  }

  AccidentSeverity _mapSeverity(double gForce, double confidence) {
    if (gForce > 4.5 || confidence > 0.88) {
      return AccidentSeverity.high;
    }
    if (gForce > 3.2 || confidence > 0.68) {
      return AccidentSeverity.medium;
    }
    return AccidentSeverity.low;
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
