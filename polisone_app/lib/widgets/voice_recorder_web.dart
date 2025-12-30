import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:html' as html;
import 'dart:async';
import 'dart:typed_data';

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
  bool _isRecording = false;
  bool _isUploading = false;
  int _recordingDuration = 0;
  Timer? _timer;
  html.MediaRecorder? _mediaRecorder;
  List<html.Blob> _recordedChunks = [];

  Future<void> _startRecording() async {
    try {
      final stream = await html.window.navigator.mediaDevices?.getUserMedia({
        'audio': true,
      });

      if (stream == null) {
        _showError('Could not access microphone');
        return;
      }

      _mediaRecorder = html.MediaRecorder(stream);
      _recordedChunks.clear();

      _mediaRecorder!.addEventListener('dataavailable', (event) {
        final data = (event as html.BlobEvent).data;
        if (data != null && data.size > 0) {
          _recordedChunks.add(data);
        }
      });

      _mediaRecorder!.addEventListener('stop', (event) {
        _processRecording();
      });

      _mediaRecorder!.start();

      setState(() {
        _isRecording = true;
        _recordingDuration = 0;
      });

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordingDuration++;
        });
        if (_recordingDuration >= 120) {
          _stopRecording();
        }
      });
    } catch (e) {
      _showError('Error starting recording: $e');
    }
  }

  void _stopRecording() {
    _timer?.cancel();
    _mediaRecorder?.stop();
    _mediaRecorder?.stream?.getTracks().forEach((track) {
      track.stop();
    });
    setState(() {
      _isRecording = false;
    });
  }

  Future<void> _processRecording() async {
    if (_recordedChunks.isEmpty) {
      _showError('No audio recorded');
      return;
    }

    setState(() => _isUploading = true);

    try {
      final blob = html.Blob(_recordedChunks, 'audio/webm');
      final reader = html.FileReader();
      reader.readAsArrayBuffer(blob);
      
      await reader.onLoadEnd.first;
      final bytes = reader.result as Uint8List;

      final fileName = 'voice_${DateTime.now().millisecondsSinceEpoch}.webm';
      final ref = FirebaseStorage.instance.ref().child('voice_messages/$fileName');
      
      final metadata = SettableMetadata(contentType: 'audio/webm');
      await ref.putData(bytes, metadata);
      final url = await ref.getDownloadURL();

      widget.onRecordingComplete(url, _recordingDuration);
      
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showError('Error uploading: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _mediaRecorder?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Record Voice Message'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isUploading)
            const CircularProgressIndicator()
          else
            GestureDetector(
              onTap: _isRecording ? _stopRecording : _startRecording,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _isRecording ? Colors.red : Colors.blue,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isRecording ? Icons.stop : Icons.mic,
                  size: 40,
                  color: Colors.white,
                ),
              ),
            ),
          const SizedBox(height: 16),
          Text(
            _isRecording 
                ? 'Recording... ${(_recordingDuration ~/ 60).toString().padLeft(2, '0')}:${(_recordingDuration % 60).toString().padLeft(2, '0')}'
                : 'Tap mic to start recording',
          ),
        ],
      ),
      actions: [
        if (!_isUploading)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
      ],
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
  bool _isPlaying = false;
  html.AudioElement? _audioElement;

  @override
  void initState() {
    super.initState();
    _audioElement = html.AudioElement(widget.audioUrl);
    _audioElement!.onEnded.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
    });
  }

  void _togglePlay() {
    if (_isPlaying) {
      _audioElement?.pause();
    } else {
      _audioElement?.play();
    }
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

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
          GestureDetector(
            onTap: _togglePlay,
            child: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${widget.duration}s',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
