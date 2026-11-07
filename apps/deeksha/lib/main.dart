import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twilight_audio/twilight_audio.dart';

import 'app.dart';
import 'config/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await BackgroundAudioQueue.initialize(
    notificationChannelId: 'com.twilight.velafm.audio',
    notificationChannelName: 'Story playback',
  );
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(VelaSystemUi.style);
  runApp(
    ProviderScope(
      overrides: buildProviderOverrides(),
      child: const VelaFmApp(),
    ),
  );
}
