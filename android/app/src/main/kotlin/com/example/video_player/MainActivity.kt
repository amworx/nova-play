package com.example.video_player

import com.ryanheise.audioservice.AudioServiceActivity

// AudioServiceActivity shares the FlutterEngine with the media-notification
// service so transport keys (shade, lock screen, headset) reach Dart.
class MainActivity : AudioServiceActivity()
