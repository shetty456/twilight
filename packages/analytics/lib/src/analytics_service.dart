import 'analytics_event.dart';

abstract class AnalyticsService {
  Future<void> track(AnalyticsEvent event);
  Future<void> identify(String userId, {Map<String, Object> traits = const {}});
  Future<void> screen(String name, {Map<String, Object> properties = const {}});
  Future<void> reset();
}
