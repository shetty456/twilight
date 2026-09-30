import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

enum RunStatus { running, failed, lamp, complete }

class RunState {
  const RunState({
    this.night = 1,
    this.lamps = 0,
    this.score = 0,
    this.status = RunStatus.running,
  });

  final int night;
  final int lamps;
  final int score;
  final RunStatus status;

  String get phase => night <= 3
      ? 'TAMAS  ·  THE EARTH'
      : night <= 6
      ? 'RAJAS  ·  THE FIRE'
      : 'SATTVA  ·  THE SKY';
}

class RunnerGame extends FlameGame {
  final ValueNotifier<RunState> state = ValueNotifier(const RunState());
  final math.Random _random = math.Random(9);
  final List<_Hazard> _hazards = [];
  bool active = false;
  double elapsed = 0;
  double _spawnClock = 0;
  int _distanceBeforeNight = 0;
  double lane = 0;
  int targetLane = 0;
  double leap = 0;
  double duck = 0;
  ui.Image? _nightOnePath;
  ui.Image? _devoteeRunOne;
  ui.Image? _devoteeRunTwo;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _nightOnePath = await images.load('night_one_path.png');
    _devoteeRunOne = await images.load('devotee_run_1.png');
    _devoteeRunTwo = await images.load('devotee_run_2.png');
  }

  void start() {
    active = true;
    elapsed = 0;
    lane = 0;
    targetLane = 0;
    _spawnClock = 0;
    _distanceBeforeNight = 0;
    _hazards.clear();
    state.value = const RunState();
  }

  void shift(int direction) {
    if (!active) return;
    targetLane = (targetLane + direction).clamp(-1, 1);
  }

  void jump() {
    if (active && leap <= 0) leap = 0.75;
  }

  void slide() {
    if (active) duck = 0.65;
  }

  void continueRun() {
    if (state.value.status != RunStatus.lamp) return;
    final nextNight = state.value.night + 1;
    _distanceBeforeNight = state.value.score;
    elapsed = 0;
    _spawnClock = 0;
    _hazards.clear();
    state.value = RunState(
      night: nextNight,
      lamps: state.value.lamps,
      score: _distanceBeforeNight,
    );
    active = true;
  }

  void retry() => start();
  void disposeState() => state.dispose();

  @override
  void update(double dt) {
    super.update(dt);
    if (!active) return;
    final step = math.min(dt, 0.05);
    elapsed += step;
    _spawnClock += step;
    lane += (targetLane - lane) * math.min(1, step * 12);
    leap = math.max(0, leap - step);
    duck = math.max(0, duck - step);
    if (_spawnClock > 1.45) {
      _spawnClock = 0;
      _hazards.add(_Hazard(_random.nextInt(3) - 1));
    }
    for (final hazard in _hazards) {
      hazard.progress += step * 0.48;
      if (!hazard.checked && hazard.progress >= 0.9) {
        hazard.checked = true;
        if (hazard.lane == targetLane && leap < 0.18) {
          active = false;
          state.value = RunState(
            night: state.value.night,
            lamps: state.value.lamps,
            score: state.value.score,
            status: RunStatus.failed,
          );
          break;
        }
      }
    }
    _hazards.removeWhere((hazard) => hazard.progress > 1.2);
    if (!active) return;
    final score = _distanceBeforeNight + (elapsed * 18).floor();
    if (score != state.value.score) {
      state.value = RunState(
        night: state.value.night,
        lamps: state.value.lamps,
        score: score,
      );
    }
    if (elapsed >= 15) {
      active = false;
      final lamps = state.value.lamps + 1;
      state.value = RunState(
        night: state.value.night,
        lamps: lamps,
        score: score,
        status: lamps == 9 ? RunStatus.complete : RunStatus.lamp,
      );
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final w = size.x;
    final h = size.y;
    if (w <= 0 || h <= 0) return;
    canvas.save();
    canvas.scale(w / 390, h / 844);
    _drawScene(canvas);
    canvas.restore();
  }

  void _drawScene(Canvas canvas) {
    final background = _nightOnePath;
    if (background != null) {
      const target = Rect.fromLTWH(0, 0, 390, 844);
      final zoom = 1.0 + (elapsed / 15).clamp(0.0, 1.0) * 0.25;
      final cropHeight = background.height / zoom;
      final cropWidth = cropHeight * 390 / 844;
      final crop = Rect.fromLTWH(
        (background.width - cropWidth) / 2,
        (background.height - cropHeight) * (305 / 844),
        cropWidth,
        cropHeight,
      );
      canvas.drawImageRect(
        background,
        crop,
        target,
        Paint()..filterQuality = FilterQuality.medium,
      );
      final tint = switch (state.value.night) {
        <= 3 => const Color(0x220D1020),
        <= 6 => const Color(0x33A33F20),
        _ => const Color(0x44B9B6D5),
      };
      canvas.drawRect(target, Paint()..color = tint);
      _drawAtmosphere(canvas);
      // Stone joints accelerate toward the camera to give the painted path depth.
      for (var i = 0; i < 8; i++) {
        final depth = ((i / 8 + elapsed * 0.42) % 1.0);
        final y = 305 + depth * depth * 530;
        final spread = 16 + depth * 190;
        canvas.drawLine(
          Offset(195 - spread, y),
          Offset(195 + spread, y),
          Paint()
            ..color = Color.fromARGB((45 + depth * 60).round(), 12, 9, 16)
            ..strokeWidth = 1 + depth * 2.5,
        );
        canvas.drawLine(
          Offset(195 - spread, y + 2),
          Offset(195 + spread, y + 2),
          Paint()
            ..color = Color.fromARGB((22 + depth * 40).round(), 255, 192, 118)
            ..strokeWidth = 1,
        );
      }
      // Passing glints on the lane edges make speed visible without obscuring hazards.
      for (var i = 0; i < 10; i++) {
        final depth = ((i / 10 + elapsed * 0.55) % 1.0);
        final y = 305 + depth * depth * 530;
        final edge = 11 + depth * 116;
        for (final side in [-1, 1]) {
          canvas.drawLine(
            Offset(195 + side * edge, y),
            Offset(195 + side * (edge + 2 + depth * 5), y + 4 + depth * 12),
            Paint()
              ..color = Color.fromARGB((35 + depth * 80).round(), 255, 196, 113)
              ..strokeWidth = 1.2 + depth,
          );
        }
      }
    } else {
      const sky = Rect.fromLTWH(0, 0, 390, 844);
      final stage = state.value.night <= 3
          ? 0
          : state.value.night <= 6
          ? 1
          : 2;
      final skyColors = switch (stage) {
        0 => const [Color(0xFF100D1D), Color(0xFF342037), Color(0xFF9F6044)],
        1 => const [Color(0xFF241019), Color(0xFF79332D), Color(0xFFD58A4C)],
        _ => const [Color(0xFF292B48), Color(0xFF756C83), Color(0xFFE4B887)],
      };
      canvas.drawRect(
        sky,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: skyColors,
            stops: [0, 0.58, 1],
          ).createShader(sky),
      );
      final glow = Paint()
        ..shader = const RadialGradient(
          colors: [Color(0x99E7A65C), Color(0x00E7A65C)],
        ).createShader(const Rect.fromLTWH(95, 270, 200, 200));
      canvas.drawCircle(const Offset(195, 370), 100, glow);

      for (var i = 0; i < 8; i++) {
        final x = i.isEven ? 18.0 + i * 3 : 375.0 - i * 3;
        final top = 165.0 + i * 29;
        canvas.drawRect(
          Rect.fromLTWH(x - 13, top, 20, 315),
          Paint()..color = const Color(0xFF17131F),
        );
        canvas.drawRect(
          Rect.fromLTWH(x - 17, top, 28, 9),
          Paint()..color = const Color(0xFF6F433B),
        );
      }

      final road = Path()
        ..moveTo(165, 370)
        ..lineTo(225, 370)
        ..lineTo(465, 844)
        ..lineTo(-75, 844)
        ..close();
      canvas.drawPath(road, Paint()..color = const Color(0xFF473138));
      canvas.drawPath(
        road,
        Paint()
          ..color = const Color(0xFFC98A56)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
      for (final side in [-1, 1]) {
        canvas.drawLine(
          Offset(195 + side * 10, 370),
          Offset(195 + side * 90, 844),
          Paint()
            ..color = const Color(0x997C5B51)
            ..strokeWidth = 2,
        );
      }
      final travel = (elapsed * 140) % 110;
      for (var i = 0; i < 7; i++) {
        final y = 390.0 + i * 90 + travel;
        if (y > 844) continue;
        final spread = (y - 370) * 0.56;
        canvas.drawLine(
          Offset(195 - spread, y),
          Offset(195 + spread, y),
          Paint()
            ..color = const Color(0x886F5650)
            ..strokeWidth = 2,
        );
      }
    }

    // The lamp carried at the horizon grows brighter with each completed night.
    final lampRadius =
        4.0 + state.value.lamps * 1.1 + math.sin(elapsed * 8) * 0.6;
    canvas.drawCircle(
      const Offset(195, 305),
      lampRadius * 2.3,
      Paint()..color = const Color(0x44FFC77A),
    );
    canvas.drawCircle(
      const Offset(195, 305),
      lampRadius,
      Paint()..color = const Color(0xFFFFD69A),
    );

    for (final hazard in _hazards) {
      final p = hazard.progress.clamp(0.0, 1.0);
      final y = 305 + p * p * 500;
      final x = 195 + hazard.lane * (42 + p * 86);
      final width = 14 + p * 44;
      final height = 10 + p * 48;
      final stone = Rect.fromCenter(
        center: Offset(x, y - height / 2),
        width: width,
        height: height,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(stone, const Radius.circular(4)),
        Paint()..color = const Color(0xFF211D28),
      );
      canvas.drawLine(
        Offset(x - width / 2, y - height),
        Offset(x + width / 2, y - height),
        Paint()
          ..color = const Color(0xFFE5A86A)
          ..strokeWidth = 3,
      );
    }

    final playerX = 195.0 + lane * 120;
    final jumpY = leap > 0
        ? math.sin((0.75 - leap) / 0.75 * math.pi) * 80
        : 0.0;
    final runPhase = elapsed * math.pi * 2 * 1.55;
    final stride = active ? math.sin(runPhase) : 0.0;
    final bob = leap > 0 ? 0.0 : stride.abs() * 2.5;
    final bodyY = jumpY + bob;
    final crouch = duck > 0 ? 13.0 : 0.0;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(playerX, 784),
        width: 78 - jumpY * 0.28,
        height: 20 - jumpY * 0.08,
      ),
      Paint()..color = Color.fromARGB((135 - jumpY * 0.7).round(), 8, 6, 12),
    );
    final sprite =
        (stride >= 0 ? _devoteeRunOne : _devoteeRunTwo) ?? _devoteeRunOne;
    if (sprite != null) {
      final height = duck > 0 ? 115.0 : 182.0;
      final width = height * sprite.width / sprite.height;
      canvas.save();
      canvas.translate(playerX, 786 - jumpY - bob);
      canvas.rotate((targetLane - lane) * -0.1);
      canvas.drawImageRect(
        sprite,
        Rect.fromLTWH(0, 0, sprite.width.toDouble(), sprite.height.toDouble()),
        Rect.fromLTWH(-width / 2, -height, width, height),
        Paint()..filterQuality = FilterQuality.medium,
      );
      canvas.restore();
      return;
    }
    canvas.drawCircle(
      Offset(playerX, 688 - bodyY + crouch),
      duck > 0 ? 19 : 23,
      Paint()..color = const Color(0xFFE2A76D),
    );
    final body = Path()
      ..moveTo(playerX - 23, 710 - bodyY + crouch)
      ..lineTo(playerX + 23, 710 - bodyY + crouch)
      ..lineTo(playerX + 16, 752 - bodyY)
      ..lineTo(playerX - 16, 752 - bodyY)
      ..close();
    canvas.drawPath(body, Paint()..color = const Color(0xFFBB392F));
    final scarf = Path()
      ..moveTo(playerX + 15, 712 - bodyY + crouch)
      ..quadraticBezierTo(
        playerX + 35,
        713 - bodyY,
        playerX + 41 + stride * 7,
        731 - bodyY,
      )
      ..lineTo(playerX + 29 + stride * 5, 725 - bodyY)
      ..close();
    canvas.drawPath(scarf, Paint()..color = const Color(0xFFE46043));
    canvas.drawLine(
      Offset(playerX - 20, 715 - bodyY + crouch),
      Offset(playerX - 28 - stride * 8, 743 - bodyY + crouch),
      Paint()
        ..color = const Color(0xFFC97D58)
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 8,
    );
    canvas.drawLine(
      Offset(playerX + 20, 715 - bodyY + crouch),
      Offset(playerX + 27 + stride * 8, 743 - bodyY + crouch),
      Paint()
        ..color = const Color(0xFFC97D58)
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 8,
    );
    canvas.drawLine(
      Offset(playerX - 10, 748 - bodyY),
      Offset(playerX - 16 + stride * 11, 781 - bodyY),
      Paint()
        ..color = const Color(0xFF35202C)
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 9,
    );
    canvas.drawLine(
      Offset(playerX + 10, 748 - bodyY),
      Offset(playerX + 16 - stride * 11, 781 - bodyY),
      Paint()
        ..color = const Color(0xFF35202C)
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 9,
    );
    canvas.drawCircle(
      Offset(playerX, 688 - bodyY + crouch),
      duck > 0 ? 19 : 23,
      Paint()
        ..color = const Color(0xFFD47D49)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  void _drawAtmosphere(Canvas canvas) {
    // The shrine sits behind a slow veil; near edges stay darker than the road.
    final farMist = Rect.fromLTWH(
      -65 + math.sin(elapsed * 0.28) * 24,
      265,
      520,
      185,
    );
    canvas.drawOval(
      farMist,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0x385D6177), Color(0x005D6177)],
        ).createShader(farMist),
    );
    final middleMist = Rect.fromLTWH(
      -130 + math.sin(elapsed * 0.52 + 1.7) * 38,
      455,
      650,
      120,
    );
    canvas.drawOval(
      middleMist,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0x1CB2A8A1), Color(0x00B2A8A1)],
        ).createShader(middleMist),
    );
    const leftEdge = Rect.fromLTWH(0, 330, 105, 514);
    const rightEdge = Rect.fromLTWH(285, 330, 105, 514);
    canvas.drawRect(
      leftEdge,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0x990C0A13), Color(0x000C0A13)],
        ).createShader(leftEdge),
    );
    canvas.drawRect(
      rightEdge,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0x000C0A13), Color(0x990C0A13)],
        ).createShader(rightEdge),
    );
    for (var i = 0; i < 12; i++) {
      final depth = (i / 12 + elapsed * 0.12) % 1.0;
      final y = 305 + depth * depth * 530;
      final edge = 45 + depth * 205;
      final side = i.isEven ? -1 : 1;
      canvas.drawCircle(
        Offset(195 + side * edge, y),
        0.7 + depth * 2.4,
        Paint()
          ..color = Color.fromARGB((20 + depth * 48).round(), 255, 201, 133),
      );
    }
  }
}

class _Hazard {
  _Hazard(this.lane);
  final int lane;
  double progress = 0;
  bool checked = false;
}
