import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:sign_education/data/dictionary_data.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'dart:typed_data';
import 'package:video_player/video_player.dart';
import 'package:sign_education/data/models/user_model.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/services.dart'; // For fullscreen landscape mode

enum UserType { student, teacher }

class DictionaryPage extends StatefulWidget {
  final UserModel user;
  const DictionaryPage({super.key, required this.user});

  @override
  State<DictionaryPage> createState() => _DictionaryPageState();
}

class _DictionaryPageState extends State<DictionaryPage> {
  String _searchQuery = "";
  Map<String, Uint8List?> _thumbnails = {}; // cache thumbnails
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initThumbnails();
  }

  Future<void> _initThumbnails() async {
    final Map<String, Uint8List?> thumbs = {};

    for (var item in dictData) {
      final clipPath = item["clip"];
      try {
        final byteData = await rootBundle.load(clipPath);
        final tempDir = await getTemporaryDirectory();
        final tempVideo = File('${tempDir.path}/${clipPath.split('/').last}')
          ..createSync(recursive: true)
          ..writeAsBytesSync(
            byteData.buffer.asUint8List(
              byteData.offsetInBytes,
              byteData.lengthInBytes,
            ),
          );

        final thumb = await VideoThumbnail.thumbnailData(
          video: tempVideo.path,
          imageFormat: ImageFormat.PNG,
          maxHeight: 120,
          quality: 75,
        );

        thumbs[clipPath] = thumb;
      } catch (e) {
        debugPrint("Thumbnail generation failed for $clipPath: $e");
        thumbs[clipPath] = null;
      }
    }

    setState(() {
      _thumbnails = thumbs;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Filter data based on search query
    final filteredData = dictData.where((item) {
      final en = item["en"].toString().toLowerCase();
      final ar = item["ar"].toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return en.contains(query) || ar.contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('قاموس لغة الإشارة'),
        centerTitle: true,
        elevation: 2,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ✅ Search bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: TextField(
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'ابحث عن كلمة',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    textAlign: TextAlign.start,
                    textDirection: TextDirection.rtl,
                  ),
                ),

                // ✅ GridView
                Expanded(
                  child: filteredData.isNotEmpty
                      ? GridView.builder(
                          padding: const EdgeInsets.all(8.0),
                          itemCount: filteredData.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 8,
                                childAspectRatio: 0.9,
                              ),
                          itemBuilder: (context, index) {
                            final item = filteredData[index];
                            final thumb = _thumbnails[item["clip"]];

                            return Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 3,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => VideoPlayerPage(
                                        title: "${item["en"]} - ${item["ar"]}",
                                        videoPath: item["clip"],
                                      ),
                                    ),
                                  );
                                },
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: thumb != null
                                          ? ClipRRect(
                                              borderRadius:
                                                  const BorderRadius.vertical(
                                                    top: Radius.circular(16),
                                                  ),
                                              child: Image.memory(
                                                thumb,
                                                width: double.infinity,
                                                fit: BoxFit.cover,
                                              ),
                                            )
                                          : Container(
                                              decoration: BoxDecoration(
                                                color: Colors.grey[300],
                                                borderRadius:
                                                    const BorderRadius.vertical(
                                                      top: Radius.circular(16),
                                                    ),
                                              ),
                                              child: const Icon(
                                                Icons.videocam,
                                                size: 48,
                                                color: Colors.grey,
                                              ),
                                            ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      item["en"],
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      item["ar"],
                                      style: const TextStyle(fontSize: 15),
                                    ),
                                    const SizedBox(height: 6),
                                  ],
                                ),
                              ),
                            );
                          },
                        )
                      : const Center(
                          child: Text(
                            "لا توجد نتائج",
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}

class VideoPlayerPage extends StatefulWidget {
  final String title;
  final String videoPath;

  const VideoPlayerPage({
    super.key,
    required this.title,
    required this.videoPath,
  });

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late VideoPlayerController _controller;
  bool _isPlaying = false;
  bool _isFinished = false;
  double _currentSpeed = 1.0;

  @override
  void initState() {
    super.initState();

    // ✅ Force portrait mode
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    _controller = VideoPlayerController.asset(widget.videoPath)
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
        _isPlaying = true;
        _isFinished = false;

        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

        // ✅ Listener to handle end of video
        _controller.addListener(() {
          final isEnded =
              _controller.value.position >=
              (_controller.value.duration - const Duration(milliseconds: 300));

          if (isEnded && !_controller.value.isPlaying && !_isFinished) {
            setState(() {
              _isFinished = true;
              _isPlaying = false;
            });
          } else if (!isEnded && _isFinished) {
            // reset flag if user seeks back
            setState(() => _isFinished = false);
          }
        });
      });
  }

  @override
  void dispose() {
    _controller.removeListener(() {});
    _controller.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  void _togglePlayPause() async {
    if (_isFinished) {
      // 🔁 Restart video instantly
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
                    // ✅ Blurred background
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

                    // ✅ Main centered video
                    Center(
                      child: AspectRatio(
                        aspectRatio: _controller.value.aspectRatio,
                        child: VideoPlayer(_controller),
                      ),
                    ),

                    // ✅ Center controls (rewind - play/pause/restart - forward)
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

                    // ✅ Progress bar + close button
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
                                playedColor: Colors.blueAccent,
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
