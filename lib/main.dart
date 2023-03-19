import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Music Player',
      home: AudioPlayerScreen(),
    );
  }
}

class AudioPlayerScreen extends StatefulWidget {
  const AudioPlayerScreen({Key? key}) : super(key: key);

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  late AudioPlayer _audioPlayer;

  final _playlist = ConcatenatingAudioSource(children: [
    AudioSource.uri(
      Uri.parse(
        // local mp3 file work in this format asset:///put here asset file address
          'asset:///assets/songs/Aadat - fingerstyle ( 256kbps cbr ).mp3'),
      tag: MediaItem(
        id: '0',
        title: 'aadat',
        artist: 'salman sulaiman',
        // image shows only from url link not from local asset files
        artUri: Uri.parse('https://pixabay.com/images/download/people-2944065_640.jpg?attachment'),
      ),
    ),
    AudioSource.uri(
      Uri.parse(
          'asset:///assets/songs/Starbase _ Gateway to Mars ( 256kbps cbr ).mp3'),
      tag: MediaItem(
        id: '1',
        title: 'star base',
        artist: 'elon musk',
        artUri: Uri.parse('https://via.placeholder.com/300/09f.png/fff'),
      ),
    ),
    AudioSource.uri(
      Uri.parse(
          'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3'),
      tag: MediaItem(
        id: '2',
        title: 'moonlight',
        artist: 'xxxtentios',
        artUri: Uri.parse('https://source.unsplash.com/user/c_v_r/1900x800'),
      ),
    ),
    AudioSource.uri(
      Uri.parse(
          'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3'),
      tag: MediaItem(
        id: '3',
        title: 'love yourself',
        artist: 'justin bieber',
        artUri: Uri.parse('https://source.unsplash.com/user/c_v_r/100x100'),
      ),
    ),
  ]);

  Stream<PositionData> get _positionDataStream => Rx.combineLatest3(
      _audioPlayer.positionStream,
      _audioPlayer.bufferedPositionStream,
      _audioPlayer.durationStream,
      (position, bufferedPosition, duration) =>
          PositionData(position, bufferedPosition, duration ?? Duration.zero));

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _audioPlayer = AudioPlayer();
    _init();
  }

  Future<void> _init() async {
    _audioPlayer.setLoopMode(LoopMode.all);
    _audioPlayer.setAudioSource(_playlist);
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _audioPlayer.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0.0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () {},
             icon: Icon(Icons.keyboard_arrow_down_rounded),
        ),
        actions: [
          IconButton(onPressed: () {}, icon: Icon(Icons.more_horiz)),
        ],
      ),
      body: Container(
        height: double.infinity,
        width: double.infinity,
        padding: EdgeInsets.all(10.0),
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
              Color(0xFF144771),
              Color(0xFF071A2C),
            ])),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            StreamBuilder<SequenceState?>(
                stream: _audioPlayer.sequenceStateStream,
                builder: (context, snapshot) {
                  final state = snapshot.data;
                  if (state?.sequence.isEmpty ?? true) {
                    return const SizedBox();
                  } else {
                    final metaData = state!.currentSource!.tag as MediaItem;
                    return MediaData(
                        imageUrl: metaData!.artUri.toString(),
                        title: metaData.title,
                        artist: metaData!.artist ?? '');
                  }
                }),
            StreamBuilder<PositionData>(
                stream: _positionDataStream,
                builder: (context, snapshot) {
                  final positionData = snapshot.data;
                  return ProgressBar(
                      progressBarColor: Colors.red,
                      bufferedBarColor: Colors.grey,
                      thumbColor: Colors.redAccent,
                      thumbGlowColor: Colors.red[100],
                      baseBarColor: Colors.grey[600],
                      timeLabelTextStyle: TextStyle(color: Colors.white),
                      progress: positionData?.position ?? Duration.zero,
                      buffered: positionData?.bufferedPosition ?? Duration.zero,
                      total: positionData?.duration ?? Duration.zero,
                      onSeek: _audioPlayer.seek);
                }),
            Controls(audioPlayer: _audioPlayer),
          ],
        ),
      ),
    );
  }
}

class Controls extends StatelessWidget {
  const Controls({Key? key, required this.audioPlayer}) : super(key: key);
  final AudioPlayer audioPlayer;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
            iconSize: 50,
            color: Colors.white,
            onPressed: audioPlayer.seekToPrevious, icon: Icon(Icons.skip_previous_rounded)),
        StreamBuilder<PlayerState>(
            stream: audioPlayer.playerStateStream,
            builder: (context, snapshot) {
              final playerState = snapshot.data;
              final processingState = playerState?.processingState;
              final playing = playerState?.playing;
              if (!(playing ?? false)) {
                return IconButton(
                    iconSize: 80,
                    color: Colors.white,
                    onPressed: audioPlayer.play,
                    icon: Icon(Icons.play_arrow_rounded));
              } else if (processingState != ProcessingState.completed) {
                return IconButton(
                    iconSize: 80,
                    color: Colors.white,
                    onPressed: audioPlayer.pause,
                    icon: Icon(Icons.pause_rounded));
              } else {
                return Icon(
                  Icons.play_arrow_rounded,
                  size: 80,
                  color: Colors.white,
                );
              }
            }),
        IconButton(
            iconSize: 50,
            color: Colors.white,
            onPressed: audioPlayer.seekToNext, icon: Icon(Icons.skip_next_rounded)),
      ],
    );
  }
}

class PositionData {
  final Duration position, bufferedPosition, duration;

  PositionData(this.position, this.bufferedPosition, this.duration);
}

class MediaData extends StatelessWidget {
  const MediaData(
      {Key? key,
      required this.imageUrl,
      required this.title,
      required this.artist})
      : super(key: key);
  final String imageUrl, title, artist;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                offset: Offset(2, 4),
                blurRadius: 4,
              ),
            ],
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10.0),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              height: 300,
              width: 300,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(
          height: 20.0,
        ),
        Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(
          height: 20.0,
        ),
        Text(
          artist,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
