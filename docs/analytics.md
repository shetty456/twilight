# Analytics

## The rule

> Share the mechanism. Keep the meaning local.

`packages/analytics` owns **how** events are tracked. Each product owns **what** events exist and **what** they mean.

## Shared mechanism

```dart
analytics.track(AnalyticsEvent('event_name', properties: {'key': 'value'}));
analytics.identify('user_id', traits: {'plan': 'pro'});
analytics.screen('Home');
analytics.reset(); // on logout
```

## Product-specific events

Define events near the feature that emits them:

```
apps/quiz/lib/features/quiz/quiz_events.dart
```

```dart
// quiz_events.dart
abstract final class QuizEvents {
  static AnalyticsEvent quizStarted(String quizId) =>
      AnalyticsEvent('quiz_started', properties: {'quiz_id': quizId});

  static AnalyticsEvent questionAnswered(String quizId, int questionIndex, bool correct) =>
      AnalyticsEvent('question_answered', properties: {
        'quiz_id': quizId,
        'question_index': questionIndex,
        'correct': correct,
      });

  static AnalyticsEvent quizCompleted(String quizId, double score) =>
      AnalyticsEvent('quiz_completed', properties: {
        'quiz_id': quizId,
        'score': score,
      });
}
```

Use in a feature:

```dart
final analytics = ref.read(analyticsServiceProvider);
await analytics.track(QuizEvents.quizStarted(quizId));
```

## Wiring up a real provider

Override `analyticsServiceProvider` in your app's `ProviderScope`:

```dart
analyticsServiceProvider.overrideWithValue(MyAnalyticsService())
```

During development, use `DebugAnalyticsService` (already the default for dev config in the template).
