import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/daily_log.dart';
import '../../../core/providers/providers.dart';
import '../../../core/services/ai_service.dart';
import '../../../core/widgets/common_widgets.dart';

class VoiceInputScreen extends ConsumerStatefulWidget {
  final MealType? mealType;

  const VoiceInputScreen({super.key, this.mealType});

  @override
  ConsumerState<VoiceInputScreen> createState() => _VoiceInputScreenState();
}

class _VoiceInputScreenState extends ConsumerState<VoiceInputScreen>
    with SingleTickerProviderStateMixin {
  final SpeechToText _speechToText = SpeechToText();
  final TextEditingController _textController = TextEditingController();

  bool _speechEnabled = false;
  bool _isListening = false;
  bool _isProcessing = false;
  String _lastWords = '';
  String _accumulatedText = ''; // Keep track of text across sessions
  late MealType _selectedMealType;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _selectedMealType = widget.mealType ?? MealType.lunch;
    _initSpeech();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _textController.dispose();
    _speechToText.stop();
    super.dispose();
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize(
      onStatus: (status) {
        debugPrint('[VoiceInput] Speech status: $status');
        // Only stop listening on explicit 'done' status, not on brief pauses
        if (status == 'done') {
          setState(() {
            _isListening = false;
            // Save accumulated text when session ends
            if (_textController.text.trim().isNotEmpty) {
              _accumulatedText = _textController.text.trim();
            }
          });
        }
      },
      onError: (error) {
        debugPrint('[VoiceInput] Speech error: ${error.errorMsg}');
        // Ignore 'error_no_match' during listening - this happens on brief pauses
        // Only show error for actual failures
        if (error.errorMsg != 'error_no_match' &&
            error.errorMsg != 'error_speech_timeout') {
          setState(() {
            _isListening = false;
            // Preserve accumulated text on error
            if (_textController.text.trim().isNotEmpty) {
              _accumulatedText = _textController.text.trim();
            }
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Speech error: ${error.errorMsg}'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      },
    );
    setState(() {});
  }

  void _startListening() async {
    if (!_speechEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Speech recognition not available'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isListening = true;
      _lastWords = '';
      // Save current text as accumulated before starting new session
      if (_textController.text.trim().isNotEmpty) {
        _accumulatedText = _textController.text.trim();
      }
    });

    await _speechToText.listen(
      onResult: _onSpeechResult,
      listenFor: const Duration(seconds: 60),
      pauseFor: const Duration(seconds: 5),
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: false,
        autoPunctuation: true,
      ),
      localeId: 'en_US',
    );
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {
      _isListening = false;
      // Save current text to accumulated when stopping
      if (_textController.text.trim().isNotEmpty) {
        _accumulatedText = _textController.text.trim();
      }
    });
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _lastWords = result.recognizedWords;
      // Combine accumulated text with new speech
      if (_accumulatedText.isNotEmpty && _lastWords.isNotEmpty) {
        _textController.text = '$_accumulatedText, $_lastWords';
      } else if (_lastWords.isNotEmpty) {
        _textController.text = _lastWords;
      }
      // Keep cursor at end
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: _textController.text.length),
      );
    });
  }

  Future<void> _analyzeAndLog() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please speak or type what you ate')),
      );
      return;
    }

    // Check subscription
    final subscription = ref.read(subscriptionProvider);
    if (!subscription.canUseAIScan) {
      final result = await context.push<bool>(
        AppRoutes.paywall,
        extra: {'featureType': 'ai_voice'},
      );
      if (result == true) {
        await ref.read(subscriptionProvider.notifier).refresh();
      }
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Record usage
      await ref.read(subscriptionProvider.notifier).recordAIScanUsage();

      final aiService = ref.read(aiServiceProvider);
      final food = await aiService.analyzeFoodText(text);

      await ref
          .read(foodLogProvider.notifier)
          .addFoodToMeal(_selectedMealType, food);

      final itemCount = food.subItems?.length ?? 1;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added meal with $itemCount item(s)!'),
            backgroundColor: AppColors.success,
          ),
        );

        context.pop();
        context.push(
          '${AppRoutes.foodDetail}/${food.id}',
          extra: {'food': food, 'mealType': _selectedMealType},
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Voice Log'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: LoadingOverlay(
        isLoading: _isProcessing,
        useAnalysisLoader: true,
        isImageAnalysis: false,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Meal type selector
                const Text(
                  'Add to',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: MealType.values.map((type) {
                    final isSelected = _selectedMealType == type;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedMealType = type),
                        child: Container(
                          margin: EdgeInsets.only(
                            right: type != MealType.snack ? 8 : 0,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.inputBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.border,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                type.emoji,
                                style: const TextStyle(fontSize: 20),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                type.displayName.substring(0, 3),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 32),

                // Instructions
                Text(
                  _isListening
                      ? 'Listening...'
                      : (_textController.text.isEmpty
                            ? 'Tap the microphone and say what you ate'
                            : 'Edit if needed, then tap "Log Food"'),
                  style: TextStyle(
                    fontSize: 16,
                    color: _isListening
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    fontWeight: _isListening
                        ? FontWeight.w500
                        : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                if (!_isListening && _textController.text.isEmpty)
                  Text(
                    'Example: "I had 2 eggs and a slice of toast with butter"',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textHint,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),

                const SizedBox(height: 32),

                // Microphone button
                GestureDetector(
                  onTap: _isProcessing
                      ? null
                      : (_isListening ? _stopListening : _startListening),
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _isListening ? _pulseAnimation.value : 1.0,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isListening
                                ? AppColors.primary
                                : AppColors.primary.withValues(alpha: 0.1),
                            boxShadow: _isListening
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.4,
                                      ),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Icon(
                            _isListening ? Icons.mic : Icons.mic_none,
                            size: 48,
                            color: _isListening
                                ? Colors.white
                                : AppColors.primary,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 32),

                // Text display/edit field
                Container(
                  width: double.infinity,
                  height: 150,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.inputBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Stack(
                    children: [
                      TextField(
                        controller: _textController,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: _isListening
                              ? 'Speak now...'
                              : 'Your food description will appear here',
                          hintStyle: TextStyle(color: AppColors.textHint),
                          border: InputBorder.none,
                        ),
                        onChanged: (value) {
                          // Update accumulated text when user types manually
                          setState(() {});
                        },
                      ),
                      // Clear button
                      if (_textController.text.isNotEmpty && !_isListening)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _textController.clear();
                                _accumulatedText = '';
                                _lastWords = '';
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.textHint.withValues(
                                  alpha: 0.2,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 16,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Log button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        (_isProcessing || _textController.text.trim().isEmpty)
                        ? null
                        : _analyzeAndLog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      disabledBackgroundColor: AppColors.primary.withValues(
                        alpha: 0.3,
                      ),
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.auto_awesome, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Analyze & Log',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
