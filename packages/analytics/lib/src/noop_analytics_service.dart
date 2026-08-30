import 'analytics_event.dart';
import 'analytics_service.dart';

class NoOpAnalyticsService implements AnalyticsService {
  const NoOpAnalyticsService();

  @override
  Future<void> track(AnalyticsEvent event) async {}

  @override
  Future<void> identify(String userId, {Map<String, Object> traits = const {}}) async {}

  @override
  Future<void> screen(String name, {Map<String, Object> properties = const {}}) async {}

  @override
  Future<void> reset() async {}
}
