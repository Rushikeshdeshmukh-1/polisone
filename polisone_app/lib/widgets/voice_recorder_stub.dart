import 'package:flutter/material.dart';

class VoiceMessageRecorder extends StatefulWidget {
  final Function(String audioUrl, int duration) onRecordingComplete;

  const VoiceMessageRecorder({
    Key? key,
    required this.onRecordingComplete,
  }) : super(key: key);

  @override
  State<VoiceMessageRecorder> createState() => _VoiceMessageRecorderState();
}

class _VoiceMessageRecorderState extends State<VoiceMessageRecorder> {
  @override
  Widget build(BuildContext context) {
    return const SizedBox();
  }
}

class VoiceMessagePlayer extends StatefulWidget {
  final String audioUrl;
  final int duration;
  final bool isMe;

  const VoiceMessagePlayer({
    Key? key,
    required this.audioUrl,
    required this.duration,
    this.isMe = false,
  }) : super(key: key);

  @override
  State<VoiceMessagePlayer> createState() => _VoiceMessagePlayerState();
}

class _VoiceMessagePlayerState extends State<VoiceMessagePlayer> {
  @override
  Widget build(BuildContext context) {
    return const SizedBox();
  }
}
