import '../models/sleep_track.dart';

class SleepCatalogFallback {
  static const featuredId = 'job';

  static const List<SleepTrack> tracks = [
    SleepTrack(
      id: 'job',
      title: 'Livro De Jó',
      subtitle: 'SOM DE CHUVA',
      description:
          'Mergulhe em 2h30 da história de Jó, envolto em sons de chuva suave. Ideal para noites tranquilas, com propósito e paz.',
      duration: Duration(hours: 2, minutes: 30),
      coverAsset: 'assets/images/sleep_page/recomendacao.png',
      audioUrl: null,
      isNarration: true,
    ),
    SleepTrack(
      id: 'proverbios',
      title: 'Provérbios',
      subtitle: 'SOM DE CHUVA',
      description:
          'Durante 2h, deixe os conselhos fluírem sobre você com um som relaxante de chuva, um convite à paz e à sabedoria enquanto você adormece.',
      duration: Duration(hours: 2, minutes: 2, seconds: 6),
      coverAsset: 'assets/images/sleep_page/image_1.png',
      audioUrl: null,
      isNarration: false,
    ),
    SleepTrack(
      id: 'parabolas',
      title: 'Parábolas de Jesus',
      subtitle: 'SOM DE CHUVA',
      description:
          'Uma seleção de parábolas narradas com ambiência suave para te conduzir a um sono profundo e natural.',
      duration: Duration(minutes: 40),
      coverAsset: 'assets/images/sleep_page/image_2.png',
      audioUrl: null,
      isNarration: false,
    ),
    SleepTrack(
      id: 'enoque',
      title: 'Quem Foi Enoque?',
      subtitle: 'NARRATIVA',
      description:
          'Conheça a história de Enoque em uma narrativa calma, ideal para relaxar.',
      duration: Duration(minutes: 90),
      coverAsset: 'assets/images/sleep_page/image_3.png',
      audioUrl: null,
      isNarration: true,
    ),
    SleepTrack(
      id: 'hebreus',
      title: 'Hebreus No Egito',
      subtitle: 'NARRATIVA',
      description:
          'Uma narrativa leve para ajudar a desacelerar antes de dormir.',
      duration: Duration(minutes: 120),
      coverAsset: 'assets/images/sleep_page/image_4.png',
      audioUrl: null,
      isNarration: true,
    ),
    SleepTrack(
      id: 'eclesiastes',
      title: 'Eclesiastes',
      subtitle: 'SOM DE CHUVA',
      description:
          'Reflexões profundas com uma ambientação relaxante para sua noite.',
      duration: Duration(minutes: 40),
      coverAsset: 'assets/images/sleep_music_page/image_1.png',
      audioUrl: null,
      isNarration: false,
    ),
    SleepTrack(
      id: 'marcos',
      title: 'Evangelho de Marcos',
      subtitle: 'SOM DE CHUVA',
      description: 'Uma leitura calma e guiada para um descanso restaurador.',
      duration: Duration(minutes: 90),
      coverAsset: 'assets/images/sleep_music_page/image_2.png',
      audioUrl: null,
      isNarration: false,
    ),
  ];
}
