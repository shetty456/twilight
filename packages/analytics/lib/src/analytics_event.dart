class AnalyticsEvent {
  const AnalyticsEvent(this.name, {this.properties = const {}});

  final String name;
  final Map<String, Object> properties;
}
