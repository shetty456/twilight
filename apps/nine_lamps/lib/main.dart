import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'runner_game.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final preferences = await SharedPreferences.getInstance();
  final savedLamps = (preferences.getInt('nine_lamps.progress.lamps') ?? 0)
      .clamp(0, 9);
  runApp(
    NineLampsApp(
      savedLamps: savedLamps,
      saveLamps: (value) async {
        await preferences.setInt('nine_lamps.progress.lamps', value);
      },
    ),
  );
}

class NineLampsApp extends StatelessWidget {
  const NineLampsApp({
    super.key,
    required this.savedLamps,
    required this.saveLamps,
  });

  final int savedLamps;
  final Future<void> Function(int) saveLamps;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Nine Lamps',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness: Brightness.dark,
      fontFamily: 'Manrope',
      scaffoldBackgroundColor: const Color(0xFF100E18),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFE7AA60),
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
    ),
    home: RunnerPage(savedLamps: savedLamps, saveLamps: saveLamps),
  );
}

class RunnerPage extends StatefulWidget {
  const RunnerPage({
    super.key,
    required this.savedLamps,
    required this.saveLamps,
  });

  final int savedLamps;
  final Future<void> Function(int) saveLamps;

  @override
  State<RunnerPage> createState() => _RunnerPageState();
}

class _RunnerPageState extends State<RunnerPage> {
  late final RunnerGame game;
  bool playing = false;

  @override
  void initState() {
    super.initState();
    game = RunnerGame(
      initialLamps: widget.savedLamps,
      saveLamps: widget.saveLamps,
    );
  }

  @override
  void dispose() {
    game.disposeState();
    super.dispose();
  }

  void start() {
    game.start();
    setState(() => playing = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          GameWidget(game: game),
          if (!playing) _Opening(onStart: start, savedLamps: widget.savedLamps),
          if (playing) ...[
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragEnd: (details) {
                final speed = details.primaryVelocity ?? 0;
                if (speed.abs() > 80) game.shift(speed > 0 ? 1 : -1);
              },
              onVerticalDragEnd: (details) {
                final speed = details.primaryVelocity ?? 0;
                if (speed < -80) game.jump();
                if (speed > 80) game.slide();
              },
              onTap: game.jump,
            ),
            SafeArea(
              child: AnimatedBuilder(
                animation: game.state,
                builder: (context, _) => Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _Panel(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'NIGHT ${game.state.value.night}  /  9',
                                  style: const TextStyle(
                                    color: Color(0xFFEAB978),
                                    fontSize: 12,
                                    letterSpacing: 2,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  game.state.value.phase,
                                  style: const TextStyle(
                                    color: Color(0xFFFFF2DC),
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          _Panel(
                            child: Text(
                              '${game.state.value.score} m',
                              style: const TextStyle(
                                color: Color(0xFFFFF2DC),
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed:
                                game.state.value.status == RunStatus.running
                                ? game.pauseRun
                                : null,
                            icon: const Icon(
                              Icons.pause_circle_outline_rounded,
                            ),
                            color: const Color(0xFFFFD69A),
                            tooltip: 'Pause run',
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: List.generate(
                          9,
                          (i) => Padding(
                            padding: const EdgeInsets.only(right: 7),
                            child: Icon(
                              i < game.state.value.lamps
                                  ? Icons.local_fire_department_rounded
                                  : Icons.circle_outlined,
                              size: i < game.state.value.lamps ? 18 : 12,
                              color: i < game.state.value.lamps
                                  ? const Color(0xFFFFBD5D)
                                  : const Color(0x88DDC6A6),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: game.state.value.progress,
                          minHeight: 5,
                          backgroundColor: const Color(0xAA17131D),
                          valueColor: const AlwaysStoppedAnimation(
                            Color(0xFFFFC777),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            AnimatedBuilder(
              animation: game.state,
              builder: (context, _) {
                final status = game.state.value.status;
                if (status == RunStatus.running) return const SizedBox.shrink();
                return _EndPanel(
                  status: status,
                  lamps: game.state.value.lamps,
                  onContinue: game.continueRun,
                  onRetry: game.retry,
                );
              },
            ),
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Text(
                  'SWIPE TO CHANGE LANES  •  UP TO JUMP  •  DOWN TO SLIDE',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.67),
                    fontSize: 9,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: const Color(0xCC14121C),
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: const Color(0x55F3C17B)),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: child,
    ),
  );
}

class _Opening extends StatelessWidget {
  const _Opening({required this.onStart, required this.savedLamps});
  final VoidCallback onStart;
  final int savedLamps;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      Image.asset('assets/images/world_concept.png', fit: BoxFit.cover),
      const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xE6100B14), Color(0x47100B14), Color(0xE9100B14)],
            stops: [0, 0.46, 1],
          ),
        ),
      ),
      SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 30, 24, 32),
          child: Column(
            children: [
              const Icon(
                Icons.local_fire_department_rounded,
                color: Color(0xFFFFD193),
                size: 34,
              ),
              const SizedBox(height: 4),
              const Text(
                'Nine Lamps',
                style: TextStyle(
                  fontFamily: 'CormorantGaramond',
                  fontSize: 52,
                  height: 1.05,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFFFF2DE),
                  shadows: [Shadow(color: Color(0xCC100B14), blurRadius: 16)],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'A JOURNEY THROUGH NINE NIGHTS',
                style: TextStyle(
                  color: Color(0xFFFFE1B5),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xD9151019),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0x77F2BB78)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                  child: Column(
                    children: [
                      const Text(
                        'The path remembers your light.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'CormorantGaramond',
                          fontSize: 30,
                          height: 1.08,
                          color: Color(0xFFFFF2DE),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 9),
                      const Text(
                        'Gather nine lamps. Walk toward dawn.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFFECD6BB),
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: onStart,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFFFC777),
                          foregroundColor: const Color(0xFF241408),
                          minimumSize: const Size(double.infinity, 56),
                        ),
                        child: Text(
                          savedLamps > 0 && savedLamps < 9
                              ? 'RESUME NIGHT ${savedLamps + 1}'
                              : 'BEGIN THE FIRST NIGHT',
                          style: const TextStyle(
                            fontSize: 12,
                            letterSpacing: 1.4,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

class _EndPanel extends StatelessWidget {
  const _EndPanel({
    required this.status,
    required this.lamps,
    required this.onContinue,
    required this.onRetry,
  });
  final RunStatus status;
  final int lamps;
  final VoidCallback onContinue;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final complete = status == RunStatus.complete;
    final failed = status == RunStatus.failed;
    final reachedLamp = status == RunStatus.reachedLamp;
    final paused = status == RunStatus.paused;
    final title = switch (status) {
      RunStatus.running => '',
      RunStatus.paused => 'THE JOURNEY RESTS',
      RunStatus.failed => 'THE PATH WAITS FOR YOU',
      RunStatus.reachedLamp => 'A LAMP AWAITS',
      RunStatus.lampLit when lamps == 3 => 'THE FIRE AWAKENS',
      RunStatus.lampLit when lamps == 6 => 'THE SKY OPENS',
      RunStatus.lampLit => 'A LAMP IS LIT',
      RunStatus.complete => 'THE LIGHT IS EVERYWHERE',
    };
    final message = switch (status) {
      RunStatus.running => '',
      RunStatus.paused => 'Breathe, then return to the path.',
      RunStatus.failed => 'Rise and try this night again. Your lamps remain.',
      RunStatus.reachedLamp => 'Pause. Receive the light of this night.',
      RunStatus.lampLit when lamps == 3 =>
        'Three lamps gathered. The stillness gives way to motion.',
      RunStatus.lampLit when lamps == 6 =>
        'Six lamps gathered. The path grows clear and quiet.',
      RunStatus.lampLit => '$lamps of nine lamps gathered',
      RunStatus.complete => 'Nine nights carried into one dawn.',
    };
    return ColoredBox(
      color: const Color(0xD9100E18),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (paused || failed)
                Icon(
                  paused
                      ? Icons.pause_circle_outline_rounded
                      : Icons.auto_awesome_rounded,
                  size: 58,
                  color: const Color(0xFFFFC777),
                )
              else
                SizedBox(
                  height: 120,
                  child: Image.asset('assets/images/diya_collectible.png'),
                ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFFFE8C8),
                  fontFamily: 'CormorantGaramond',
                  fontSize: 32,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: const TextStyle(color: Color(0xFFE7CCAC), fontSize: 15),
              ),
              const SizedBox(height: 30),
              FilledButton(
                onPressed: complete || failed ? onRetry : onContinue,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFE9AE63),
                  foregroundColor: const Color(0xFF21120D),
                  minimumSize: const Size(220, 52),
                ),
                child: Text(
                  complete || failed
                      ? complete
                            ? 'BEGIN AGAIN'
                            : 'TRY THIS NIGHT AGAIN'
                      : reachedLamp
                      ? 'RECEIVE THE LAMP'
                      : paused
                      ? 'RESUME'
                      : 'CONTINUE',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
