import 'package:flutter_riverpod/flutter_riverpod.dart';

class TasbihState {
  TasbihState({
    required this.counts,
    required this.activeZikrKey,
  });
  final Map<String, int> counts;
  final String activeZikrKey;

  int get activeCount => counts[activeZikrKey] ?? 0;

  int get totalCount => counts.values.fold(0, (sum, val) => sum + val);

  TasbihState copyWith({
    Map<String, int>? counts,
    String? activeZikrKey,
  }) {
    return TasbihState(
      counts: counts ?? this.counts,
      activeZikrKey: activeZikrKey ?? this.activeZikrKey,
    );
  }
}

class TasbihController extends StateNotifier<TasbihState> {
  TasbihController()
      : super(TasbihState(
          counts: {for (var key in availableAzkar) key: 0},
          activeZikrKey: availableAzkar[0],
        ));
  static const List<String> availableAzkar = [
    'zikr_subhan_allah',
    'zikr_alhamdulillah',
    'zikr_allahu_akbar',
    'zikr_la_ilaha_illa_allah',
    'zikr_astaghfirullah',
    'zikr_la_hawla_wala_quwwata_illa_billah',
    'zikr_hasbunallah_wanikmal_wakil',
    'zikr_allahumma_salli_ala_muhammad',
    'zikr_subhanallahi_wabihamdihi',
    'zikr_subhanallahi_al_azim',
    'zikr_la_ilaha_illallah_wahdahu',
    'zikr_subhanallahi_wa_bi_hamdih_adada_khalqih',
    'zikr_ya_hayyu_ya_qayyum',
    'zikr_allahumma_ajirni_minan_nar',
    'zikr_la_ilaha_illa_anta_subhanaka',
    'zikr_ya_muqallibal_qulub',
    'zikr_allahumma_innaka_afuwwun',
    'zikr_raditu_billahi_rabba',
    'zikr_allahumma_aini_ala_zhikrika',
    'zikr_hasbi_allah_walahu_al_arsh',
    'zikr_subhan_allah_walhamdu_lillah',
    'zikr_ya_dhal_jalali_wal_ikram',
    'zikr_la_ilaha_illallah_al_malik',
    'zikr_astaghfirullah_lil_muminin',
    'zikr_allahumma_maghfiratuka_awsa',
    'zikr_allahumma_salli_ala_muhammad_full',
    'zikr_allahumma_inni_asalukal_jannah',
    'zikr_la_ilaha_illallah_al_azim_al_halim',
  ];

  void increment() {
    final newCounts = Map<String, int>.from(state.counts);
    newCounts[state.activeZikrKey] = (newCounts[state.activeZikrKey] ?? 0) + 1;
    state = state.copyWith(counts: newCounts);
  }

  void setActiveZikr(String key) {
    if (availableAzkar.contains(key)) {
      state = state.copyWith(activeZikrKey: key);
    }
  }

  void resetActive() {
    final newCounts = Map<String, int>.from(state.counts);
    newCounts[state.activeZikrKey] = 0;
    state = state.copyWith(counts: newCounts);
  }

  void resetAll() {
    state = state.copyWith(
      counts: {for (var key in availableAzkar) key: 0},
    );
  }
}

final tasbihControllerProvider =
    StateNotifierProvider.autoDispose<TasbihController, TasbihState>((ref) {
  return TasbihController();
});
