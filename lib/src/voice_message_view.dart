import 'package:flutter/material.dart';
import 'package:voice_message_package/src/helpers/play_status.dart';
import 'package:voice_message_package/src/helpers/utils.dart';
import 'package:voice_message_package/src/voice_controller.dart';
import 'package:voice_message_package/src/widgets/noises.dart';
import 'package:voice_message_package/src/widgets/play_pause_button.dart';

/// A widget that displays a voice message view with play/pause functionality.
///
/// The [VoiceMessageView] widget is used to display a voice message with customizable appearance and behavior.
/// It provides a play/pause button, a progress slider, and a counter for the remaining time.
/// The appearance of the widget can be customized using various properties such as background color, slider color, and text styles.
///
class VoiceMessageView extends StatelessWidget {
  const VoiceMessageView(
      {Key? key,
      required this.controller,
      this.backgroundColor = Colors.white,
      this.activeSliderColor = Colors.red,
      this.notActiveSliderColor,
      this.circlesColor = Colors.red,
      this.innerPadding = 12,
      this.cornerRadius = 20,
      // this.playerWidth = 170,
      this.size = 38,
      this.refreshIcon = const Icon(
        Icons.refresh,
        color: Colors.white,
      ),
      this.pauseIcon = const Icon(
        Icons.pause_rounded,
        color: Colors.white,
      ),
      this.playIcon = const Icon(
        Icons.play_arrow_rounded,
        color: Colors.white,
      ),
      this.stopDownloadingIcon = const Icon(
        Icons.close,
        color: Colors.white,
      ),
      this.playPauseButtonDecoration,
      this.circlesTextStyle = const TextStyle(
        color: Colors.white,
        fontSize: 10,
        fontWeight: FontWeight.bold,
      ),
      this.counterTextStyle = const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
      this.playPauseButtonLoadingColor = Colors.white})
      : super(key: key);

  /// The controller for the voice message view.
  final VoiceController controller;

  /// The background color of the voice message view.
  final Color backgroundColor;

  ///
  final Color circlesColor;

  /// The color of the active slider.
  final Color activeSliderColor;

  /// The color of the not active slider.
  final Color? notActiveSliderColor;

  /// The text style of the circles.
  final TextStyle circlesTextStyle;

  /// The text style of the counter.
  final TextStyle counterTextStyle;

  /// The padding between the inner content and the outer container.
  final double innerPadding;

  /// The corner radius of the outer container.
  final double cornerRadius;

  /// The size of the play/pause button.
  final double size;

  /// The refresh icon of the play/pause button.
  final Widget refreshIcon;

  /// The pause icon of the play/pause button.
  final Widget pauseIcon;

  /// The play icon of the play/pause button.
  final Widget playIcon;

  /// The stop downloading icon of the play/pause button.
  final Widget stopDownloadingIcon;

  /// The play Decoration of the play/pause button.
  final Decoration? playPauseButtonDecoration;

  /// The loading Color of the play/pause button.
  final Color playPauseButtonLoadingColor;

  // Helper function to format duration
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  /// Build voice message view.
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final color = circlesColor;
    final newTHeme = theme.copyWith(
      sliderTheme: SliderThemeData(
        trackShape: CustomTrackShape(),
        thumbShape: SliderComponentShape.noThumb,
        minThumbSeparation: 0,
      ),
      splashColor: Colors.transparent,
    );

    // --- START OF HEIGHT AND PADDING ADJUSTMENTS ---
    // Define a consistent height for the main interactive elements.
    // Using 48.0 to give a bit more presence and vertical space for content.
    const double targetElementHeight = 48.0;

    // Adjusted inner padding for the overall container (message bubble)
    const double adjustedInnerPadding = 2.0; // Even less padding as requested
    // --- END OF HEIGHT AND PADDING ADJUSTMENTS ---

    return Container(
      width: 160 + (controller.noiseCount * .72.w()),
      padding: EdgeInsets.all(adjustedInnerPadding), // Use adjusted padding for the bubble
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(cornerRadius),
      ),
      child: ValueListenableBuilder<dynamic>(
        valueListenable: controller.updater,
        builder: (context, _, child) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, // Vertically center all items in this row
            children: [
              /// play pause button - Fixed to targetElementHeight
              PlayPauseButton(
                controller: controller,
                color: color,
                loadingColor: playPauseButtonLoadingColor,
                size: targetElementHeight, // Explicitly set size
                refreshIcon: refreshIcon,
                pauseIcon: pauseIcon,
                playIcon: playIcon,
                stopDownloadingIcon: stopDownloadingIcon,
                buttonDecoration: playPauseButtonDecoration,
              ),

              /// Spacing between play button and waveform
              const SizedBox(width: 2),

              /// waveform (slider & noises) - Fixed to targetElementHeight
              Expanded(
                child: SizedBox(
                  height: targetElementHeight, // Explicitly set height
                  width: controller.noiseWidth,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      /// noises (the full waveform bars, always visible)
                      Noises(
                        rList: controller.randoms!,
                        activeSliderColor: activeSliderColor,
                      ),
                      /// slider (the progress line over noises, representing the UNPLAYED portion)
                      AnimatedBuilder(
                        animation: CurvedAnimation(
                          parent: controller.animController,
                          curve: Curves.ease,
                        ),
                        builder: (BuildContext context, Widget? child) {
                          return Positioned(
                            left: controller.animController.value,
                            child: Container(
                              width: controller.noiseWidth,
                              height: 6.w(), // Visual height of the slider line itself
                              color: notActiveSliderColor ?? backgroundColor.withOpacity(.4),
                            ),
                          );
                        },
                      ),
                      /// The transparent slider for user interaction (seeking)
                      Opacity(
                        opacity: 0,
                        child: Container(
                          width: controller.noiseWidth,
                          color: Colors.transparent.withOpacity(1),
                          child: Theme(
                            data: newTHeme,
                            child: Slider(
                              value: controller.currentMillSeconds,
                              max: controller.maxMillSeconds,
                              onChangeStart: controller.onChangeSliderStart,
                              onChanged: controller.onChanging,
                              onChangeEnd: (value) {
                                controller.onSeek(
                                  Duration(milliseconds: value.toInt()),
                                );
                                controller.play();
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              /// Spacing between waveform and timestamp/speed control column
              const SizedBox(width: 2),

              /// Column for timestamp (countdown) and speed control (below timestamp)
              SizedBox( // Wrapper SizedBox to enforce overall height
                height: targetElementHeight, // Explicitly set height for the column
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center, // Distribute space evenly between children
                  crossAxisAlignment: CrossAxisAlignment.end, // Align contents to the right within the column
                  children: [
                    /// timestamp (countdown)
                    Text(
                      _formatDuration(
                        (controller.currentDuration == Duration.zero && controller.playStatus != PlayStatus.playing)
                            ? controller.maxDuration
                            : (controller.maxDuration - controller.currentDuration).isNegative
                                ? Duration.zero
                                : (controller.maxDuration - controller.currentDuration),
                      ),
                      style: TextStyle(
                        fontSize: 16, // Font size for readability
                        fontWeight: counterTextStyle.fontWeight,
                        color: counterTextStyle.color,
                      ),
                    ),

                    /// speed button (inside a tiny pill container)
                    _changeSpeedButton(color),
                  ],
                ),
              ),

              /// Trailing space
              const SizedBox(width: 10),
            ],
          );
        },
      ),
    );
  }

  /// Helper method for the speed button, which returns a pill-shaped container
  Transform _changeSpeedButton(Color color) => Transform.translate(
        offset: const Offset(0, 0), // No vertical offset, let Column's mainAxisAlignment handle positioning
        child: GestureDetector(
          onTap: () {
            controller.changeSpeed();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), // Adjusted padding for pill
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10), // Rounded corners for pill shape
            ),
            child: Text(
              controller.speed.playSpeedStr,
              style: circlesTextStyle.copyWith(fontSize: 9), // Compact font size for the pill
            ),
          ),
        ),
      );
}

/// A custom track shape for a slider that is rounded rectangular in shape.
class CustomTrackShape extends RoundedRectSliderTrackShape {
  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    const double trackHeight = 10;
    final double trackLeft = offset.dx,
        trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }
}