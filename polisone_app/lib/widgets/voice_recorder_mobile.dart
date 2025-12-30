
import 'package:flutter/material.dart';

class VoiceMessageRecorder extends StatefulWidget {
  final Function(String, int) onRecordingComplete;

  const VoiceMessageRecorder({Key? key, required this.onRecordingComplete}) : super(key: key);

  @override
  State<VoiceMessageRecorder> createState() => _VoiceMessageRecorderState();
}

class _VoiceMessageRecorderState extends State<VoiceMessageRecorder> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: const Center(
        child: Text('Voice recording not supported on mobile yet'),
      ),
    );
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.mic_off, color: Colors.grey),
          const SizedBox(width: 8),
          Text('${widget.duration}s (No Playback)'),
        ],
      ),
    );
  }
}
