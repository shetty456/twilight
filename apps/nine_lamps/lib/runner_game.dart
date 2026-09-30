import 'dart:math' as math;

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
      if (!hazard.checked && hazard.progress >= 0.82) {
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
          night: state.value.night, lamps: state.value.lamps, score: score);
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
    const sky = Rect.fromLTWH(0, 0, 390, 844);
    final stage = state.value.night <= 3 ? 0 : state.value.night <= 6 ? 1 : 2;
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
      ..shader = const RadialGradient(colors: [Color(0x99E7A65C), Color(0x00E7A65C)])
          .createShader(const Rect.fromLTWH(95, 270, 200, 200));
    canvas.drawCircle(const Offset(195, 370), 100, glow);

    // The lamp carried at the horizon grows brighter with each completed night.
    final lampRadius = 4.0 + state.value.lamps * 1.1;
    canvas.drawCircle(const Offset(195, 372), lampRadius * 2.3,
        Paint()..color = const Color(0x44FFC77A));
    canvas.drawCircle(const Offset(195, 372), lampRadius,
        Paint()..color = const Color(0xFFFFD69A));

    for (var i = 0; i < 8; i++) {
      final x = i.isEven ? 18.0 + i * 3 : 375.0 - i * 3;
      final top = 165.0 + i * 29;
      canvas.drawRect(
          Rect.fromLTWH(x - 13, top, 20, 315), Paint()..color = const Color(0xFF17131F));
      canvas.drawRect(
          Rect.fromLTWH(x - 17, top, 28, 9), Paint()..color = const Color(0xFF6F433B));
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
          ..strokeWidth = 3);
    for (final side in [-1, 1]) {
      canvas.drawLine(Offset(195 + side * 10, 370), Offset(195 + side * 90, 844),
          Paint()..color = const Color(0x997C5B51)..strokeWidth = 2);
    }
    final travel = (elapsed * 140) % 110;
    for (var i = 0; i < 7; i++) {
      final y = 390.0 + i * 90 + travel;
      if (y > 844) continue;
      final spread = (y - 370) * 0.56;
      canvas.drawLine(Offset(195 - spread, y), Offset(195 + spread, y),
          Paint()..color = const Color(0x886F5650)..strokeWidth = 2);
    }

    for (final hazard in _hazards) {
      final p = hazard.progress.clamp(0.0, 1.0);
      final y = 390 + p * p * 415;
      final x = 195 + hazard.lane * (17 + p * 82);
      final width = 14 + p * 44;
      final height = 10 + p * 48;
      final stone = Rect.fromCenter(
          center: Offset(x, y - height / 2), width: width, height: height);
      canvas.drawRRect(
          RRect.fromRectAndRadius(stone, const Radius.circular(4)),
          Paint()..color = const Color(0xFF211D28));
      canvas.drawLine(Offset(x - width / 2, y - height), Offset(x + width / 2, y - height),
          Paint()..color = const Color(0xFFE5A86A)..strokeWidth = 3);
    }

    final playerX = 195.0 + lane * 86;
    final jumpY = leap > 0 ? math.sin((0.75 - leap) / 0.75 * math.pi) * 80 : 0.0;
    canvas.drawOval(Rect.fromCenter(center: Offset(playerX, 740), width: 51, height: 15),
        Paint()..color = const Color(0x990B0910));
    canvas.drawCircle(Offset(playerX, 688 - jumpY), 23,
        Paint()..color = const Color(0xFFE2A76D));
    final body = Path()
      ..moveTo(playerX - 23, 710 - jumpY)
      ..lineTo(playerX + 23, 710 - jumpY)
      ..lineTo(playerX + 16, 752 - jumpY)
      ..lineTo(playerX - 16, 752 - jumpY)
      ..close();
    canvas.drawPath(body, Paint()..color = const Color(0xFFBB392F));
    canvas.drawLine(Offset(playerX - 10, 748 - jumpY), Offset(playerX - 16, 781 - jumpY),
        Paint()..color = const Color(0xFF35202C)..strokeWidth = 9);
    canvas.drawLine(Offset(playerX + 10, 748 - jumpY), Offset(playerX + 16, 781 - jumpY),
        Paint()..color = const Color(0xFF35202C)..strokeWidth = 9);
    canvas.drawCircle(Offset(playerX, 688 - jumpY), 23,
        Paint()..color = const Color(0xFFD47D49)..style = PaintingStyle.stroke..strokeWidth = 3);
  }
}

class _Hazard {
  _Hazard(this.lane);
  final int lane;
  double progress = 0;
  bool checked = false;
}
