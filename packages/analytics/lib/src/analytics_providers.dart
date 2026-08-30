import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'analytics_service.dart';
import 'noop_analytics_service.dart';

final analyticsServiceProvider = Provider<AnalyticsService>(
  (_) => const NoOpAnalyticsService(),
);
