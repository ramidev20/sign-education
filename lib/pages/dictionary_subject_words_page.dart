import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:sign_education/data/dictionary_data.dart';
import 'package:sign_education/pages/dictionary_video_player_page.dart';
import 'package:sign_education/utils/app_strings.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class DictionarySubjectWordsPage extends StatefulWidget {
  final String subjectId;
  final String subjectTitle;
  final Color subjectColor;

  const DictionarySubjectWordsPage({
    super.key,
    required this.subjectId,
    required this.subjectTitle,
    required this.subjectColor,
  });

  @override
  State<DictionarySubjectWordsPage> createState() =>
      _DictionarySubjectWordsPageState();
}

class _DictionarySubjectWordsPageState extends State<DictionarySubjectWordsPage> {
  String _searchQuery = '';
  Map<String, Uint8List?> _thumbnails = {};
  bool _isLoading = true;

  List<Map<String, dynamic>> get _subjectWords =>
      dictData.where((w) => w['subject'] == widget.subjectId).toList();

  @override
  void initState() {
    super.initState();
    _initThumbnails();
  }

  Future<void> _initThumbnails() async {
    if (kIsWeb) {
      if (!mounted) return;
      setState(() {
        _thumbnails = const {};
        _isLoading = false;
      });
      return;
    }

    final thumbs = <String, Uint8List?>{};
    final words = _subjectWords;

    for (final item in words) {
      final clipPath = item['clip'] as String;
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
          maxHeight: 140,
          quality: 75,
        );

        thumbs[clipPath] = thumb;
      } catch (_) {
        thumbs[clipPath] = null;
      }
    }

    if (!mounted) return;
    setState(() {
      _thumbnails = thumbs;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final words = _subjectWords;
    final filtered = words.where((item) {
      final en = item['en'].toString().toLowerCase();
      final ar = item['ar'].toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return en.contains(query) || ar.contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subjectTitle),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: TextField(
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: strings.searchForWord,
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Text(
                            strings.noWordsFound,
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.black54,
                            ),
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(10),
                          itemCount: filtered.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                                childAspectRatio: 0.88,
                              ),
                          itemBuilder: (context, index) {
                            final item = filtered[index];
                            final clipPath = item['clip'] as String;
                            final thumb = _thumbnails[clipPath];

                            return _WordCard(
                              english: item['en'].toString(),
                              arabic: item['ar'].toString(),
                              difficulty: item['difficulty'].toString(),
                              color: widget.subjectColor,
                              thumb: thumb,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DictionaryVideoPlayerPage(
                                      title: '${item["en"]} - ${item["ar"]}',
                                      videoPath: clipPath,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class _WordCard extends StatelessWidget {
  final String english;
  final String arabic;
  final String difficulty;
  final Color color;
  final Uint8List? thumb;
  final VoidCallback onTap;

  const _WordCard({
    required this.english,
    required this.arabic,
    required this.difficulty,
    required this.color,
    required this.thumb,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.25)),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: thumb != null
                        ? Image.memory(thumb!, fit: BoxFit.cover)
                        : Container(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            child: Icon(
                              Icons.videocam_rounded,
                              size: 44,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _DifficultyChip(difficulty: difficulty),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              child: Column(
                children: [
                  Text(
                    english,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    arabic,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DifficultyChip extends StatelessWidget {
  final String difficulty;
  const _DifficultyChip({required this.difficulty});

  String _label(BuildContext context) {
    final strings = AppStrings.of(context);
    switch (difficulty) {
      case 'easy':
        return strings.easy;
      case 'medium':
        return strings.medium;
      case 'hard':
        return strings.hard;
      default:
        return difficulty;
    }
  }

  Color get _color {
    switch (difficulty) {
      case 'easy':
        return const Color(0xFF2E7D32);
      case 'medium':
        return const Color(0xFFF57C00);
      case 'hard':
        return const Color(0xFFC62828);
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.92),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        _label(context),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
