import 'dart:developer' as dev;

import 'analytics_event.dart';
import 'analytics_service.dart';

class DebugAnalyticsService implements AnalyticsService {
  const DebugAnalyticsService();

  @override
  Future<void> track(AnalyticsEvent event) async {
    dev.log('[Analytics] track: ${event.name} ${event.properties}',
        name: 'Analytics');
  }

  @override
  Future<void> identify(String userId,
      {Map<String, Object> traits = const {}}) async {
    dev.log('[Analytics] identify: $userId $traits', name: 'Analytics');
  }

  @override
  Future<void> screen(String name,
      {Map<String, Object> properties = const {}}) async {
    dev.log('[Analytics] screen: $name $properties', name: 'Analytics');
  }

  @override
  Future<void> reset() async {
    dev.log('[Analytics] reset', name: 'Analytics');
  }
}
