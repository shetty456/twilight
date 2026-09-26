# Shared UI

`ui` contains presentation building blocks that can be used by any Twilight app. Import `package:ui/ui.dart`. Keep product names, routes, network calls, and feature-specific widgets in the app that owns them.

## Theme

Each app can supply its brand color and font family while using the same component styling:

```dart
const design = AppThemeConfig(
  primaryColor: Color(0xFF006B5E),
  fontFamily: 'MyAppFont',
);

MaterialApp(
  theme: AppTheme.light(config: design),
  darkTheme: AppTheme.dark(config: design),
  home: const HomePage(),
);
```

The existing `AppTheme.light(primaryColor: ...)` API remains available. Shared widgets read colors and text styles from `Theme.of(context)`; apps should prefer the theme's `ColorScheme` over fixed colors.

## Components

| Group | Public APIs |
| --- | --- |
| Actions | `AppButton`, `AppButtonVariant` |
| Forms | `AppTextField`, `AppTextArea`, `AppDropdown`, `AppCheckbox`, `AppRadio`, `AppSwitch` |
| Content | `AppCard`, `AppChip`, `AppBadge`, `AppDivider` |
| States | `LoadingWidget`, `AppEmptyState`, `AppErrorState` |
| Loading layouts | `AppSkeleton`, `AppSkeletonList` |
| Feedback | `AppMessageBox`, `AppMessageKind`, `AppSnackbar`, `AppConfirmationSheet` |

For form validation, place `AppTextField` or `AppDropdown` inside a `Form` and pass a `validator`. Provide all user-facing copy at the call site so each app can localize it.

`AppSkeleton(isLoading: true, child: yourScreen)` turns an existing layout into a shimmer skeleton. For lists, provide sample items while loading or use `AppSkeletonList`, because an empty list has no widgets to transform. The shared UI package uses `skeletonizer` for this effect.
