import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';

class CameraScreen extends StatelessWidget {
  const CameraScreen({super.key});

  static const _cameras = [
    _CameraFeed('Camera 1', 'assets/videos/camera_1.mp4'),
    _CameraFeed('Camera 2', 'assets/videos/camera_2.mp4'),
    _CameraFeed('Camera 3', 'assets/videos/camera_3.mp4'),
    _CameraFeed('Camera 4', 'assets/videos/camera_4.mp4'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Camera Wall',
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Local video feeds',
                    style: GoogleFonts.dmSans(
                      color: const Color(0xFF8B949E),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 88),
                itemCount: _cameras.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.78,
                ),
                itemBuilder: (context, index) {
                  return _CameraTile(feed: _cameras[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraFeed {
  final String title;
  final String assetPath;

  const _CameraFeed(this.title, this.assetPath);
}

class _CameraTile extends StatefulWidget {
  final _CameraFeed feed;

  const _CameraTile({required this.feed});

  @override
  State<_CameraTile> createState() => _CameraTileState();
}

class _CameraTileState extends State<_CameraTile> {
  late final VideoPlayerController _controller;
  bool _ready = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(widget.feed.assetPath)
      ..setLooping(true)
      ..setVolume(0);
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _controller.initialize();
      await _controller.play();
      if (!mounted) {
        return;
      }
      setState(() => _ready = true);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        color: const Color(0xFF161B22),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_ready)
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              )
            else if (_failed)
              const Center(
                child: Icon(
                  Icons.videocam_off_outlined,
                  color: Color(0xFFFF6B6B),
                  size: 32,
                ),
              )
            else
              const Center(
                child: CircularProgressIndicator(color: Color(0xFF00D4AA)),
              ),
            Positioned(
              left: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xCC0D1117),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.circle, color: Color(0xFF00D4AA), size: 8),
                    const SizedBox(width: 6),
                    Text(
                      widget.feed.title,
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 6,
              bottom: 6,
              child: IconButton(
                tooltip: _controller.value.isPlaying ? 'Duraklat' : 'Oynat',
                visualDensity: VisualDensity.compact,
                color: Colors.white,
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xCC0D1117),
                ),
                onPressed: _ready
                    ? () {
                        setState(() {
                          if (_controller.value.isPlaying) {
                            _controller.pause();
                          } else {
                            _controller.play();
                          }
                        });
                      }
                    : null,
                icon: Icon(
                  _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
