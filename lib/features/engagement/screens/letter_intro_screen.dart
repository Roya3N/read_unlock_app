import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:read_unlock_app/features/reading/screens/letter_journey_screen.dart';

class LetterIntroScreen extends StatefulWidget {
  final String letter;

  const LetterIntroScreen({super.key, required this.letter});

  @override
  State<LetterIntroScreen> createState() => _LetterIntroScreenState();
}

class _LetterIntroScreenState extends State<LetterIntroScreen> {
  // ⭐️ Audio Player Setup
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  // ⭐️ Apnar nijer kora A to Z data (Kono kichu delete kora hoyni)
  final Map<String, Map<String, String>> alphabetData = {
    'A': {
      'emoji': '🍎',
      'words': 'Apple • Ant',
      'sentence':
          'I brought an apple because an apple starts with the short A sound.',
    },
    'B': {
      'emoji': '🐻',
      'words': 'Bear • Ball',
      'sentence': 'The big brown bear bounced the ball in the yard.',
    },
    'C': {
      'emoji': '🐱',
      'words': 'Cat • Car',
      'sentence': 'The cute cat is sleeping in the blue car.',
    },
    'D': {
      'emoji': '🐶',
      'words': 'Dog • Drum',
      'sentence': 'The happy dog played the drum loudly.',
    },
    'E': {
      'emoji': '🦅',
      'words': 'Elephant • Egg',
      'sentence': 'The elephant carefully carried the egg.',
    },
    'F': {
      'emoji': '🐟',
      'words': 'Fish • Frog',
      'sentence': 'The fish and the frog swam in the pond.',
    },
    'G': {
      'emoji': '🦒',
      'words': 'Goat • Gift',
      'sentence': 'The goat found a shiny gift in the grass.',
    },
    'H': {
      'emoji': '🏠',
      'words': 'House • Hat',
      'sentence': 'The red hat is inside the little house.',
    },
    'I': {
      'emoji': '🍦',
      'words': 'Ice Cream • Insect',
      'sentence': 'The tiny insect looked at the ice cream.',
    },
    'J': {
      'emoji': '🧃',
      'words': 'Juice • Jelly',
      'sentence': 'I drank sweet juice with strawberry jelly.',
    },
    'K': {
      'emoji': '🪁',
      'words': 'Kite • Key',
      'sentence': 'The colorful kite flew near the silver key.',
    },
    'L': {
      'emoji': '🦁',
      'words': 'Lion • Lamp',
      'sentence': 'The lion slept beside the bright lamp.',
    },
    'M': {
      'emoji': '🐵',
      'words': 'Monkey • Moon',
      'sentence': 'The monkey pointed at the shining moon.',
    },
    'N': {
      'emoji': '👃',
      'words': 'Nose • Nest',
      'sentence': 'The bird built a nest near my nose.',
    },
    'O': {
      'emoji': '🐙',
      'words': 'Octopus • Orange',
      'sentence': 'The octopus held a juicy orange.',
    },
    'P': {
      'emoji': '🐼',
      'words': 'Panda • Pizza',
      'sentence': 'The panda ate a slice of pizza happily.',
    },
    'Q': {
      'emoji': '👑',
      'words': 'Queen • Quilt',
      'sentence': 'The queen wrapped herself in a warm quilt.',
    },
    'R': {
      'emoji': '🐰',
      'words': 'Rabbit • Rainbow',
      'sentence': 'The rabbit hopped under the rainbow.',
    },
    'S': {
      'emoji': '⭐',
      'words': 'Star • Sun',
      'sentence': 'The bright star sparkled beside the sun.',
    },
    'T': {
      'emoji': '🐯',
      'words': 'Tiger • Train',
      'sentence': 'The tiger watched the long train pass by.',
    },
    'U': {
      'emoji': '☂️',
      'words': 'Umbrella • Unicorn',
      'sentence': 'The unicorn carried a colorful umbrella.',
    },
    'V': {
      'emoji': '🎻',
      'words': 'Violin • Van',
      'sentence': 'The violin was left inside the blue van.',
    },
    'W': {
      'emoji': '🐋',
      'words': 'Whale • Watch',
      'sentence': 'The whale splashed water near the watch.',
    },
    'X': {
      'emoji': '📦',
      'words': 'Xylophone • Box',
      'sentence': 'The xylophone was hidden inside the box.',
    },
    'Y': {
      'emoji': '🪀',
      'words': 'Yo-Yo • Yak',
      'sentence': 'The yak played with a yellow yo-yo.',
    },
    'Z': {
      'emoji': '🦓',
      'words': 'Zebra • Zoo',
      'sentence': 'The zebra ran happily around the zoo.',
    },
  };

  @override
  void initState() {
    super.initState();
    // Audio Player er state check korar jonno
    _audioPlayer.onDurationChanged.listen((d) => setState(() => _duration = d));
    _audioPlayer.onPositionChanged.listen((p) => setState(() => _position = p));
    _audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() => _isPlaying = state == PlayerState.playing);
    });
    _audioPlayer.onPlayerComplete.listen((event) {
      setState(() {
        _isPlaying = false;
        _position = Duration.zero;
      });
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  // ⭐️ ElevenLabs MP3 File Play Korar System
  Future<void> _toggleAudio() async {
    HapticFeedback.lightImpact();

    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      try {
        // Apnar ElevenLabs folder theke direct play hobe
        await _audioPlayer.play(
          AssetSource('sounds/ElevenLabs/${widget.letter.toUpperCase()}.mp3'),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Audio file not found! 📢")),
        );
      }
    }
  }

  String _formatDuration(Duration d) {
    return "${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final letterInfo =
        alphabetData[widget.letter.toUpperCase()] ??
        {
          'emoji': '✨',
          'words': 'Word 1. Word 2.',
          'sentence': 'Let us learn the letter ${widget.letter} together!',
        };

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9F0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFFD97757),
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: const Text(
          "Learn the Letter",
          style: TextStyle(
            color: Color(0xFFD97757),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: const Color(0xFFF2D5C4), width: 2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD97757).withOpacity(0.05),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      widget.letter.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 80,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFE05B3A),
                        height: 1.0,
                      ),
                    ).animate().scale(
                      duration: 500.ms,
                      curve: Curves.easeOutBack,
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF0E6),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              "Listen",
                              style: TextStyle(
                                color: Color(0xFFD97757),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "Letter ${widget.letter.toUpperCase()}",
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF333333),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            letterInfo['words']!.replaceAll('.', ' •'),
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF0E6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            letterInfo['emoji']!,
                            style: const TextStyle(fontSize: 30),
                          ),
                        )
                        .animate(
                          onPlay: (controller) =>
                              controller.repeat(reverse: true),
                        )
                        .scale(
                          begin: const Offset(1.0, 1.0),
                          end: const Offset(1.1, 1.1),
                          duration: 1.seconds,
                        ),
                  ],
                ),

                const SizedBox(height: 30),

                // ⭐️ Pro Audio Player Card with progress bar
                _buildAudioTrackCard(
                  title: "${widget.letter.toUpperCase()} Phonics & Words",
                ),

                const SizedBox(height: 30),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("💬", style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Say it aloud",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF333333),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              letterInfo['sentence']!,
                              style: const TextStyle(
                                color: Colors.black54,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.heavyImpact();
                      _audioPlayer.stop(); // Stop audio when navigating
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              LetterJourneyScreen(letter: widget.letter),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4ADE80),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 5,
                      shadowColor: const Color(0xFF4ADE80).withOpacity(0.4),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Start Tasks",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 10),
                        Icon(Icons.arrow_forward_rounded, color: Colors.white),
                      ],
                    ),
                  ),
                ).animate().slideY(
                  begin: 1,
                  duration: 600.ms,
                  curve: Curves.easeOutBack,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAudioTrackCard({required String title}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _isPlaying ? const Color(0xFFFFF4F1) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isPlaying ? const Color(0xFFE05B3A) : const Color(0xFFF2D5C4),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 12,
                backgroundColor: Color(0xFFE05B3A),
                child: Icon(
                  Icons.music_note_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF333333),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  _isPlaying
                      ? Icons.pause_circle_filled_rounded
                      : Icons.play_circle_fill_rounded,
                ),
                color: const Color(0xFFE05B3A),
                iconSize: 36,
                onPressed: _toggleAudio,
              ),
              const SizedBox(width: 5),
              Text(
                _isPlaying
                    ? "${_formatDuration(_position)} / ${_formatDuration(_duration)}"
                    : "00:00 / 00:00",
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                    ),
                    activeTrackColor: const Color(0xFFE05B3A),
                    inactiveTrackColor: const Color(0xFFF2D5C4),
                    thumbColor: const Color(0xFFE05B3A),
                  ),
                  child: Slider(
                    value: _isPlaying && _duration.inSeconds > 0
                        ? _position.inSeconds.toDouble()
                        : 0.0,
                    min: 0.0,
                    max: _isPlaying && _duration.inSeconds > 0
                        ? _duration.inSeconds.toDouble()
                        : 1.0,
                    onChanged: (value) {
                      if (_isPlaying) {
                        _audioPlayer.seek(Duration(seconds: value.toInt()));
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
