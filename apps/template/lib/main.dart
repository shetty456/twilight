import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'config/providers.dart';

void main() {
  runApp(
    ProviderScope(
      overrides: buildProviderOverrides(),
      child: const App(),
    ),
  );
}
