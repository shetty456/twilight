import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'audio_cues.dart';
import 'runner_game.dart' show RunState, RunStatus;

enum _Obstacle { stone, arch }

class _PlacedObstacle {
  _PlacedObstacle(this.x, this.kind);
  final double x;
  final _Obstacle kind;
  bool checked = false;
}

class _Offering {
  _Offering(this.x, this.high);
  final double x;
  final bool high;
  bool collected = false;
}

/// A camera-led side view of the journey. Distances are in world pixels.
class SideScrollGame extends FlameGame {
  SideScrollGame({
    required int initialLamps,
    required Future<void> Function(int) saveLamps,
  }) : _saveLamps = saveLamps {
    final lamps = initialLamps.clamp(0, 9);
    state = ValueNotifier(RunState(
      night: math.min(lamps + 1, 9),
      lamps: lamps,
      score: lamps * 270,
      status: lamps == 9 ? RunStatus.complete : RunStatus.running,
    ));
  }

  late final ValueNotifier<RunState> state;
  final Future<void> Function(int) _saveLamps;
  final math.Random _random = math.Random(91);
  final List<_PlacedObstacle> _obstacles = [];
  final List<_Offering> _offerings = [];
  ui.Image? _landscape;
  ui.Image? _devoteeSheet;
  ui.Image? _diya;
  ui.Image? _stone;
  ui.Image? _arch;
  ui.Image? _pillar;
  ui.Image? _lotus;
  bool active = false;
  double elapsed = 0;
  double _spawnClock = 0;
  double _offeringClock = 0;
  double _jumpTime = 0;
  double _slideTime = 0;
  double _cameraX = 0;
  int _scoreBase = 0;
  int _offeringCount = 0;
  int _offeringSequence = 0;

  static const _runSeconds = 15.0;
  static const _speed = 144.0;
  static const _groundY = 675.0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _landscape = await images.load('side_valley_night.png');
    _devoteeSheet = await images.load('devotee_run_sheet.png');
    _diya = await images.load('diya_collectible.png');
    _stone = await images.load('temple_stone_low.png');
    _arch = await images.load('temple_arch_low.png');
    _pillar = await images.load('temple_pillar_near.png');
    _lotus = await images.load('lotus_offering.png');
  }

  void start() {
    final previous = state.value.lamps;
    final lamps = previous == 9 ? 0 : previous;
    _scoreBase = lamps * 270;
    _resetMotion();
    state.value = RunState(night: lamps + 1, lamps: lamps, score: _scoreBase);
    active = true;
    if (previous == 9) unawaited(_persist(0));
  }

  void jump() {
    if (active && _jumpTime <= 0 && _slideTime <= 0) _jumpTime = 0.82;
  }

  void slide() {
    if (active && _slideTime <= 0 && _jumpTime <= 0) _slideTime = 0.72;
  }

  void pauseRun() {
    if (!active) return;
    active = false;
    state.value = _copy(status: RunStatus.paused);
  }

  void retry() {
    if (state.value.status == RunStatus.complete) {
      start();
    } else if (state.value.status == RunStatus.failed) {
      _resetMotion();
      state.value = RunState(
        night: state.value.night,
        lamps: state.value.lamps,
        score: _scoreBase,
      );
      active = true;
    }
  }

  void continueRun() {
    final status = state.value.status;
    if (status == RunStatus.paused) {
      state.value = _copy(status: RunStatus.running);
      active = true;
    } else if (status == RunStatus.reachedLamp) {
      unawaited(AudioCues.lamp());
      final lamps = state.value.lamps + 1;
      unawaited(_persist(lamps));
      state.value = RunState(
        night: state.value.night,
        lamps: lamps,
        score: state.value.score,
        offerings: _offeringCount,
        progress: 1,
        status: lamps == 9 ? RunStatus.complete : RunStatus.lampLit,
      );
    } else if (status == RunStatus.lampLit) {
      _scoreBase = state.value.score;
      _resetMotion();
      state.value = RunState(
        night: state.value.night + 1,
        lamps: state.value.lamps,
        score: _scoreBase,
      );
      active = true;
    }
  }

  RunState _copy({required RunStatus status}) => RunState(
    night: state.value.night,
    lamps: state.value.lamps,
    score: state.value.score,
    offerings: _offeringCount,
    progress: state.value.progress,
    status: status,
  );

  void _resetMotion() {
    active = false;
    elapsed = 0;
    _spawnClock = 0;
    _offeringClock = 0;
    _jumpTime = 0;
    _slideTime = 0;
    _cameraX = 0;
    _obstacles.clear();
    _offerings.clear();
    _offeringCount = 0;
    _offeringSequence = 0;
  }

  Future<void> _persist(int lamps) async {
    try {
      await _saveLamps(lamps);
    } catch (error) {
      debugPrint('Could not save lamp progress: $error');
    }
  }

  void disposeState() => state.dispose();

  @override
  void update(double dt) {
    super.update(dt);
    if (!active) return;
    final step = math.min(dt, 0.05);
    elapsed += step;
    _spawnClock += step;
    _offeringClock += step;
    _jumpTime = math.max(0, _jumpTime - step);
    _slideTime = math.max(0, _slideTime - step);
    final playerWorldX = elapsed * _speed;
    _cameraX += (playerWorldX - _cameraX) * math.min(1, step * 5);
    final interval = math.max(1.18, 1.8 - (state.value.night - 1) * 0.065);
    if (_spawnClock >= interval && elapsed < 10.8) {
      _spawnClock = 0;
      final kind = state.value.night <= 2 || _random.nextDouble() < 0.62
          ? _Obstacle.stone
          : _Obstacle.arch;
      _obstacles.add(_PlacedObstacle(playerWorldX + 480, kind));
    }
    if (_offeringClock >= 1.12 && elapsed < 11.7) {
      _offeringClock = 0;
      _offerings.add(_Offering(playerWorldX + 390, _offeringSequence % 3 == 2));
      _offeringSequence++;
    }
    for (final obstacle in _obstacles) {
      if (obstacle.checked || obstacle.x - playerWorldX > 20) continue;
      obstacle.checked = true;
      final safe = obstacle.kind == _Obstacle.stone
          ? _jumpTime > 0.18
          : _slideTime > 0.12;
      if (!safe) {
        active = false;
        HapticFeedback.mediumImpact();
        unawaited(AudioCues.hit());
        state.value = _copy(status: RunStatus.failed);
        return;
      }
    }
    _obstacles.removeWhere((o) => o.x < playerWorldX - 300);
    for (final offering in _offerings) {
      if (offering.collected || (offering.x - playerWorldX).abs() > 25) continue;
      offering.collected = true;
      if (!offering.high || _jumpTime > 0.18) {
        _offeringCount++;
        HapticFeedback.selectionClick();
      }
    }
    _offerings.removeWhere((o) => o.x < playerWorldX - 80);
    final score = _scoreBase + (elapsed * 18).floor() + _offeringCount * 25;
    if (score != state.value.score || _offeringCount != state.value.offerings) {
      state.value = RunState(
        night: state.value.night,
        lamps: state.value.lamps,
        score: score,
        offerings: _offeringCount,
        progress: (elapsed / _runSeconds).clamp(0, 1),
      );
    }
    if (elapsed >= _runSeconds) {
      active = false;
      _obstacles.clear();
      state.value = _copy(status: RunStatus.reachedLamp);
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (size.x <= 0 || size.y <= 0) return;
    canvas.save();
    canvas.scale(size.x / 390, size.y / 844);
    _paintWorld(canvas);
    canvas.restore();
  }

  void _paintWorld(Canvas canvas) {
    final stage = state.value.night <= 3 ? 0 : state.value.night <= 6 ? 1 : 2;
    final glow = stage == 0 ? const Color(0xFFE8A867) :
        stage == 1 ? const Color(0xFFFFBD79) : const Color(0xFFFFDFB0);
    const sky = Rect.fromLTWH(0, 0, 390, 844);
    canvas.drawRect(sky, Paint()..shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: stage == 0
          ? const [Color(0xFF090B1B), Color(0xFF1A2134), Color(0xFF664B4A)]
          : stage == 1
          ? const [Color(0xFF201322), Color(0xFF593F4E), Color(0xFFA47B65)]
          : const [Color(0xFF393758), Color(0xFF908599), Color(0xFFE4B990)],
    ).createShader(sky));

    // The panoramic painting moves slowly while distinct temple, tree and
    // foreground silhouettes pass the camera at progressively faster speeds.
    final landscape = _landscape;
    if (landscape != null) {
      const imageHeight = 520.0;
      final imageWidth = imageHeight * landscape.width / landscape.height;
      final shift = (_cameraX * 0.12) % imageWidth;
      for (var i = -1; i < 2; i++) {
        canvas.drawImageRect(
          landscape,
          Rect.fromLTWH(0, 0, landscape.width.toDouble(), landscape.height.toDouble()),
          Rect.fromLTWH(i * imageWidth - shift, 165, imageWidth, imageHeight),
          Paint()..filterQuality = FilterQuality.medium,
        );
      }
    }
    _paintLayer(canvas, 0.22, 540, const Color(0xB8182234), 170);
    _paintLayer(canvas, 0.52, 625, const Color(0xFF222331), 125);

    const ground = Rect.fromLTWH(0, _groundY, 390, 169);
    canvas.drawRect(ground, Paint()..color = const Color(0xFF211B24));
    canvas.drawRect(const Rect.fromLTWH(0, _groundY, 390, 7),
        Paint()..color = const Color(0xFFBD855C));
    final pavingShift = _cameraX % 78;
    for (var i = -1; i < 7; i++) {
      final x = i * 78.0 - pavingShift;
      canvas.drawLine(Offset(x, _groundY + 9), Offset(x - 21, 844),
          Paint()..color = const Color(0xFF52404A)..strokeWidth = 2);
      canvas.drawLine(Offset(x, _groundY + 60), Offset(x + 78, _groundY + 60),
          Paint()..color = const Color(0xFF493844)..strokeWidth = 2);
    }

    const playerX = 108.0;
    final playerWorldX = elapsed * _speed;
    for (final obstacle in _obstacles) {
      final x = playerX + obstacle.x - playerWorldX;
      if (x < -90 || x > 470) continue;
      _paintObstacle(canvas, obstacle, x);
    }
    for (final offering in _offerings) {
      if (offering.collected) continue;
      final x = playerX + offering.x - playerWorldX;
      if (x < -40 || x > 430) continue;
      final y = _groundY - (offering.high ? 172 : 94) +
          math.sin(elapsed * 6 + offering.x * 0.02) * 4;
      canvas.drawCircle(Offset(x, y), 23,
          Paint()..color = const Color(0x55F8BF72));
      _paintImage(canvas, _lotus, Rect.fromCenter(
          center: Offset(x, y), width: 34, height: 34));
    }
    if (elapsed >= 11.3 || state.value.status == RunStatus.reachedLamp) {
      final x = state.value.status == RunStatus.reachedLamp
          ? 270.0 : playerX + (15 - elapsed) * _speed;
      _paintImage(canvas, _diya, Rect.fromLTWH(x - 28, _groundY - 80, 56, 76));
      canvas.drawCircle(Offset(x, _groundY - 62), 57,
          Paint()..color = glow.withValues(alpha: 0.10));
    }

    _paintPlayer(canvas, playerX);
    _paintForeground(canvas);
    final vignette = Paint()..shader = const RadialGradient(
      colors: [Color(0x00000000), Color(0x88080713)],
      stops: [0.48, 1],
    ).createShader(sky);
    canvas.drawRect(sky, vignette);
  }

  void _paintLayer(Canvas canvas, double speed, double baseY, Color color, double spacing) {
    final offset = (_cameraX * speed) % spacing;
    for (var i = -2; i < 5; i++) {
      final x = i * spacing - offset;
      final tall = i.isEven;
      final top = baseY - (tall ? 176 : 124);
      canvas.drawRect(Rect.fromLTWH(x + 18, top + 30, 15, baseY - top - 30),
          Paint()..color = color);
      final crown = Path()
        ..moveTo(x - 38, top + 78)
        ..quadraticBezierTo(x + 22, top - 70, x + 84, top + 78)
        ..close();
      canvas.drawPath(crown, Paint()..color = color);
      if (speed > 0.4) {
        canvas.drawRect(Rect.fromLTWH(x + 82, baseY - 80, 16, 80),
            Paint()..color = color);
        canvas.drawRect(Rect.fromLTWH(x + 73, baseY - 88, 34, 11),
            Paint()..color = const Color(0xFF6D4E48));
      }
    }
  }

  void _paintObstacle(Canvas canvas, _PlacedObstacle obstacle, double x) {
    final stone = obstacle.kind == _Obstacle.stone;
    canvas.drawOval(Rect.fromCenter(center: Offset(x, _groundY + 3), width: 65, height: 13),
        Paint()..color = const Color(0xAA08070C));
    _paintImage(canvas, stone ? _stone : _arch,
        stone ? Rect.fromLTWH(x - 35, _groundY - 53, 70, 54)
              : Rect.fromLTWH(x - 43, _groundY - 132, 86, 132));
  }

  void _paintPlayer(Canvas canvas, double x) {
    const duration = 0.82;
    final jump = _jumpTime > 0
        ? math.sin((duration - _jumpTime) / duration * math.pi) * 105 : 0.0;
    final stride = active ? math.sin(elapsed * 16) : 0.0;
    final bob = _jumpTime > 0 ? 0.0 : stride.abs() * 4;
    canvas.drawOval(Rect.fromCenter(center: Offset(x, _groundY + 3),
        width: 58 - jump * 0.2, height: 14 - jump * 0.04),
        Paint()..color = const Color(0x9907060C));
    final height = _slideTime > 0 ? 102.0 : 160.0;
    canvas.save();
    canvas.translate(x, _groundY + 27 - jump - bob);
    canvas.rotate(_jumpTime > 0 ? -0.10 : stride * 0.028);
    final sheet = _devoteeSheet;
    if (sheet != null) {
      final frame = _jumpTime > 0 ? 4 : active ? ((elapsed * 12).floor() % 4) : 0;
      final source = Rect.fromLTWH(
        frame * sheet.width / 6,
        0,
        sheet.width / 6,
        sheet.height.toDouble(),
      );
      canvas.drawImageRect(sheet, source,
          Rect.fromLTWH(-46, -height - 27, 92, height + 27),
          Paint()..filterQuality = FilterQuality.medium);
    }
    canvas.restore();
    if (active && _jumpTime <= 0 && _slideTime <= 0) {
      canvas.drawCircle(Offset(x - 39, _groundY - 10), 2.5,
          Paint()..color = const Color(0x77E8AA70));
    }
  }

  void _paintForeground(Canvas canvas) {
    const spacing = 340.0;
    final offset = (_cameraX * 1.18) % spacing;
    for (var i = -1; i < 3; i++) {
      final x = i * spacing - offset + 250;
      _paintImage(canvas, _pillar,
          Rect.fromLTWH(x - 32, 160, 88, 530));
    }
  }

  void _paintImage(Canvas canvas, ui.Image? image, Rect destination) {
    if (image == null) return;
    canvas.drawImageRect(image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        destination, Paint()..filterQuality = FilterQuality.medium);
  }
}
