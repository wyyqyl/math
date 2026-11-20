import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

abstract final class GameTapSound {
  static final _pool = AudioPool.createFromAsset(
    path: 'audio/tap.mp3',
    minPlayers: 0,
    maxPlayers: 3,
  );

  static void play() => unawaited(_play());

  static Future<void> _play() async {
    try {
      final pool = await _pool;
      await pool.start();
    } catch (error) {
      debugPrint('Could not play answer sound: $error');
    }
  }
}
