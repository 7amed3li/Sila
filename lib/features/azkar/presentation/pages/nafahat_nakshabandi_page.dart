import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sila_app/core/theme/app_theme.dart';
import 'package:sila_app/features/azkar/presentation/riverpod/nafahat_audio_controller.dart';

class NafahatNakshabandiPage extends ConsumerWidget {
  const NafahatNakshabandiPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioState = ref.watch(nafahatAudioControllerProvider);
    final audioController = ref.read(nafahatAudioControllerProvider.notifier);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor =
        isDark ? const Color(0xFF10B981) : AppTheme.primaryColor;
    final bgColor =
        isDark ? AppTheme.darkBackgroundColor : const Color(0xFFF1F5F9);
    final cardColor =
        isDark ? AppTheme.darkSurfaceColor.withValues(alpha: 0.8) : Colors.white;

    final currentIbtihal = audioState.currentIbtihal;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // ── Background Decorations ──
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryColor.withValues(alpha: 0.05),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ── Header ──
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.arrow_back_ios_new_rounded,
                            color:
                                isDark ? Colors.white : AppTheme.primaryColor),
                      ),
                      Expanded(
                        child: Text(
                          'spiritual_nafahat'.tr(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color:
                                isDark ? Colors.white : AppTheme.primaryColor,
                          ),
                        ),
                      ),
                      _buildSleepTimerMenu(context, ref, audioState),
                    ],
                  ),
                ),

                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      // ── Main Player Card ──
                      SliverPadding(
                        padding: const EdgeInsets.all(20),
                        sliver: SliverToBoxAdapter(
                          child: _buildPlayerCard(context, audioState,
                              audioController, isDark, primaryColor, cardColor),
                        ),
                      ),

                      // ── Playlist Header ──
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 8),
                        sliver: SliverToBoxAdapter(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'playlist'.tr(),
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      isDark ? Colors.white70 : Colors.black87,
                                ),
                              ),
                              _buildFilterMenu(context, ref, audioState),
                            ],
                          ),
                        ),
                      ),

                      // ── Playlist Items ──
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final ibtihal =
                                  audioState.filteredPlaylist[index];
                              final isSelected =
                                  audioState.currentIndex == index;
                              return _buildPlaylistItem(
                                  context,
                                  ref,
                                  ibtihal,
                                  index,
                                  isSelected,
                                  audioController,
                                  isDark,
                                  primaryColor,
                                  audioState.selectedArtist == null);
                            },
                            childCount: audioState.filteredPlaylist.length,
                          ),
                        ),
                      ),

                      const SliverToBoxAdapter(child: SizedBox(height: 40)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerCard(
      BuildContext context,
      NafahatPlayerState state,
      NafahatAudioController controller,
      bool isDark,
      Color primaryColor,
      Color cardColor) {
    final current = state.currentIbtihal;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Artwork (Hasanah/Nakshabandi)
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                image: DecorationImage(
                  image: NetworkImage(
                    current?.id.startsWith('T') == true
                        ? 'https://archive.org/download/mo7ammad-altookhy----reeding-quran-____telawat--khashe3ah---7aflat-mogawwadah/Mo7ammad-altookhy-1.png'
                        : 'https://archive.org/download/20240309_20240309_1714/%D8%A7%D8%A8%D8%AA%D9%87%D8%A7%D9%84%D8%A7%D8%AA%20%D8%A7%D9%84%D8%B4%D9%8A%D8%AE%20%D8%B3%D9%8A%D8%AF%20%D8%A7%D9%84%D9%86%D9%82%D8%B4%D8%A8%D9%86%D8%AF%D9%8A.jpg',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
                  ),
                ),
                padding: const EdgeInsets.all(20),
                alignment: Alignment.bottomRight,
                child: Text(
                  current?.title ?? '...',
                  style: const TextStyle(
                    fontFamily: 'Amiri',
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Progress Bar
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 14),
                    activeTrackColor: primaryColor,
                    inactiveTrackColor: primaryColor.withValues(alpha: 0.2),
                    thumbColor: primaryColor,
                  ),
                  child: Slider(
                    value: state.position.inSeconds.toDouble(),
                    max: state.duration.inSeconds.toDouble() > 0
                        ? state.duration.inSeconds.toDouble()
                        : 1.0,
                    onChanged: (value) =>
                        controller.seek(Duration(seconds: value.toInt())),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatDuration(state.position),
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                      Text(_formatDuration(state.duration),
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      onPressed: controller.previous,
                      icon: Icon(Icons.skip_previous_rounded,
                          size: 36,
                          color: isDark ? Colors.white : Colors.black87),
                    ),
                    GestureDetector(
                      onTap: controller.togglePlay,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.4),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: state.isLoading
                            ? const SizedBox(
                                width: 32,
                                height: 32,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 3))
                            : Icon(
                                state.playerState.playing
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                size: 40,
                                color: Colors.white,
                              ),
                      ),
                    ),
                    IconButton(
                      onPressed: controller.next,
                      icon: Icon(Icons.skip_next_rounded,
                          size: 36,
                          color: isDark ? Colors.white : Colors.black87),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistItem(
      BuildContext context,
      WidgetRef ref,
      ibtihal,
      int index,
      bool isSelected,
      NafahatAudioController controller,
      bool isDark,
      Color primaryColor,
      bool showArtist) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? primaryColor.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        onTap: () => controller.playIbtihal(index),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isSelected
                ? primaryColor
                : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: isSelected &&
                    ref
                        .watch(nafahatAudioControllerProvider)
                        .playerState
                        .playing
                ? const Icon(Icons.equalizer_rounded,
                    color: Colors.white, size: 20)
                : Text('${index + 1}',
                    style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white70 : Colors.black54),
                        fontWeight: FontWeight.bold)),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ibtihal.title,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? primaryColor
                    : (isDark ? Colors.white : Colors.black87),
              ),
            ),
            if (showArtist)
              Text(
                ibtihal.artistName,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
          ],
        ),
        trailing: isSelected
            ? Icon(Icons.volume_up_rounded, color: primaryColor, size: 20)
            : const Icon(Icons.play_circle_outline_rounded,
                color: Colors.grey, size: 20),
      ),
    );
  }

  Widget _buildSleepTimerMenu(
      BuildContext context, WidgetRef ref, NafahatPlayerState state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = ref.read(nafahatAudioControllerProvider.notifier);

    return PopupMenuButton<int>(
      icon: Icon(
        state.sleepTimerDuration != null
            ? Icons.timer_rounded
            : Icons.timer_outlined,
        color: state.sleepTimerDuration != null
            ? const Color(0xFF10B981)
            : (isDark ? Colors.white70 : Colors.black54),
      ),
      onSelected: (minutes) {
        if (minutes == 0) {
          controller.setSleepTimer(null);
        } else {
          controller.setSleepTimer(Duration(minutes: minutes));
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(value: 15, child: Text('15_minutes'.tr())),
        PopupMenuItem(value: 30, child: Text('30_minutes'.tr())),
        PopupMenuItem(value: 60, child: Text('60_minutes'.tr())),
        PopupMenuItem(
            value: 0,
            child: Text('cancel_timer'.tr(),
                style: const TextStyle(color: Colors.red))),
      ],
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Widget _buildFilterMenu(
      BuildContext context, WidgetRef ref, NafahatPlayerState state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = ref.read(nafahatAudioControllerProvider.notifier);
    final artists = controller.getAvailableArtists();

    return PopupMenuButton<String?>(
      icon: Icon(
        Icons.tune_rounded,
        color: state.selectedArtist != null
            ? const Color(0xFF10B981)
            : (isDark ? Colors.white70 : Colors.black54),
      ),
      onSelected: controller.setArtistFilter,
      itemBuilder: (context) => [
        PopupMenuItem(
          value: null,
          child: Text('all'.tr(), style: const TextStyle(fontFamily: 'Cairo')),
        ),
        ...artists.map((artist) => PopupMenuItem(
              value: artist,
              child: Text(artist, style: const TextStyle(fontFamily: 'Cairo')),
            )),
      ],
    );
  }
}
