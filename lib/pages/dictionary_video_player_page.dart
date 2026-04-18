import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sign_education/utils/app_theme.dart';
import 'package:video_player/video_player.dart';

class DictionaryVideoPlayerPage extends StatefulWidget {
  final String title;
  final String videoPath;

  const DictionaryVideoPlayerPage({
    super.key,
    required this.title,
    required this.videoPath,
  });

  @override
  State<DictionaryVideoPlayerPage> createState() =>
      _DictionaryVideoPlayerPageState();
}

class _DictionaryVideoPlayerPageState extends State<DictionaryVideoPlayerPage> {
  late VideoPlayerController _controller;
  bool _isPlaying = false;
  bool _isFinished = false;
  double _currentSpeed = 1.0;

  @override
  void initState() {
    super.initState();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    _controller = VideoPlayerController.asset(widget.videoPath)
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() {});
        _controller.play();
        _isPlaying = true;
        _isFinished = false;

        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

        _controller.addListener(_handleVideoListener);
      });
  }

  void _handleVideoListener() {
    final isEnded =
        _controller.value.position >=
        (_controller.value.duration - const Duration(milliseconds: 300));

    if (isEnded && !_controller.value.isPlaying && !_isFinished) {
      setState(() {
        _isFinished = true;
        _isPlaying = false;
      });
    } else if (!isEnded && _isFinished) {
      setState(() => _isFinished = false);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleVideoListener);
    _controller.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  Future<void> _togglePlayPause() async {
    if (_isFinished) {
      await _controller.seekTo(Duration.zero);
      await _controller.play();
      setState(() {
        _isFinished = false;
        _isPlaying = true;
      });
      return;
    }

    if (_controller.value.isPlaying) {
      await _controller.pause();
      setState(() => _isPlaying = false);
    } else {
      await _controller.play();
      setState(() {
        _isPlaying = true;
        _isFinished = false;
      });
    }
  }

  void _speedDown() {
    if (_currentSpeed > 0.25) {
      _currentSpeed -= 0.25;
      _controller.setPlaybackSpeed(_currentSpeed);
      setState(() {});
    }
  }

  void _speedUp() {
    if (_currentSpeed < 1.0) {
      _currentSpeed += 0.25;
      _controller.setPlaybackSpeed(_currentSpeed);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: _controller.value.isInitialized
              ? Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: FittedBox(
                              fit: BoxFit.cover,
                              child: SizedBox(
                                width: _controller.value.size.width,
                                height: _controller.value.size.height,
                                child: VideoPlayer(_controller),
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                              child: Container(
                                color: Colors.black.withOpacity(0.4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Center(
                      child: AspectRatio(
                        aspectRatio: _controller.value.aspectRatio,
                        child: VideoPlayer(_controller),
                      ),
                    ),
                    Positioned(
                      bottom: 90,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.fast_rewind_rounded),
                            color: Colors.white,
                            iconSize: 45,
                            onPressed: _speedDown,
                          ),
                          const SizedBox(width: 30),
                          IconButton(
                            icon: Icon(
                              _isFinished
                                  ? Icons.replay_circle_filled
                                  : (_isPlaying
                                      ? Icons.pause_circle_filled
                                      : Icons.play_circle_fill),
                            ),
                            color: Colors.white,
                            iconSize: 70,
                            onPressed: _togglePlayPause,
                          ),
                          const SizedBox(width: 30),
                          IconButton(
                            icon: const Icon(Icons.fast_forward_rounded),
                            color: Colors.white,
                            iconSize: 45,
                            onPressed: _speedUp,
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        color: Colors.black54,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            VideoProgressIndicator(
                              _controller,
                              allowScrubbing: true,
                              colors: const VideoProgressColors(
                                playedColor: AppTheme.brand,
                                bufferedColor: Colors.white54,
                                backgroundColor: Colors.black26,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.white70,
                                  ),
                                  onPressed: () => Navigator.pop(context),
                                ),
                                Text(
                                  "${_currentSpeed.toStringAsFixed(2)}x",
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(width: 48),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}

