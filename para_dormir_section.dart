import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '/core/theme/styles.dart';
import '/features/bible/presentation/pages/player/audio_player_page.dart';

class ParaDormirSection extends StatelessWidget {
  const ParaDormirSection({super.key});

  @override
  Widget build(BuildContext context) {
    final audioItems = [
      {
        'title': 'JÓ AO SOM DE CHUVA',
        'image': 'assets/images/jo.png',
        'audioUrl':
            'https://drive.google.com/file/d/1XW55id4UuI90pSLNq6cdQ2s7I2h_npsT/view?usp=sharing',
      },
      {
        'title': 'Parábolas de Jesus AO SOM DE CHUVA',
        'image': 'assets/images/parabolas.png',
        'audioUrl':
            'https://drive.google.com/file/d/1ttQsUDOmmA8St4gsCTvLQ58jOb_8I8js/view?usp=sharing',
      },
      {
        'title': 'PROVÉRBIOS AO SOM DE CHUVA',
        'image': 'assets/images/proverbios.png',
        'audioUrl':
            'https://drive.google.com/file/d/1fr5DH9Gv8wJ_NGLjq_R40ShdvgaiayAx/view?usp=sharing',
      },
      {
        'title': 'ECLESIASTES AO SOM DE CHUVA',
        'image': 'assets/images/eclesiastes.png',
        'audioUrl':
            'https://drive.google.com/file/d/1Fyn_3r6wnfEqk8DIKnKeCVLhcOjvCvJs/view?usp=sharing',
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(context, 'Pra Dormir'),
          SizedBox(
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: audioItems.length,
              itemBuilder: (context, index) {
                final item = audioItems[index];
                return _audioCard(
                  context: context,
                  title: item['title']!,
                  imageUrl: item['image']!,
                  audioUrl: item['audioUrl']!,
                  audioItems: audioItems,
                  index: index,
                );
              },
              separatorBuilder: (_, __) => const SizedBox(width: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _audioCard(
      {required BuildContext context,
      required String title,
      required String imageUrl,
      required String audioUrl,
      required List<Map<String, String>> audioItems,
      required int index}) {
    return SizedBox(
      width: 160,
      child: GestureDetector(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => AudioPlayerPage(
              playlist: audioItems,
              currentIndex: index,
            ),
          );
        },
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(imageUrl,
                  height: 120, width: 160, fit: BoxFit.cover),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            )
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context, String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        TextButton(
          onPressed: () {},
          child: const Text('Ver mais'),
        )
      ],
    );
  }
}
