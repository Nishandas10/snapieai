import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/barcode_service.dart';
import '../../../core/services/ai_service.dart';
import '../../../core/models/daily_log.dart';
import '../../../core/providers/providers.dart';

class BarcodeScannerScreen extends ConsumerStatefulWidget {
  final MealType? mealType;

  const BarcodeScannerScreen({super.key, this.mealType});

  @override
  ConsumerState<BarcodeScannerScreen> createState() =>
      _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends ConsumerState<BarcodeScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _isProcessing = false;
  bool _hasScanned = false;
  String? _lastScannedBarcode;
  String? _statusMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onBarcodeDetected(BarcodeCapture capture) async {
    if (_isProcessing || _hasScanned) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final barcode = barcodes.first.rawValue;
    if (barcode == null || barcode == _lastScannedBarcode) return;

    setState(() {
      _isProcessing = true;
      _hasScanned = true;
      _lastScannedBarcode = barcode;
      _statusMessage = 'Looking up product...';
    });

    // Stop scanning
    await _controller.stop();

    // Lookup product in OpenFoodFacts
    final barcodeService = BarcodeService();
    final productInfo = await barcodeService.lookupBarcode(barcode);

    if (!mounted) return;

    if (productInfo != null) {
      // Product found - now analyze with AI for complete nutrition data
      setState(() {
        _statusMessage = 'Analyzing ${productInfo.fullName}...';
      });

      try {
        final aiService = AIService();
        final foodItem = await aiService.analyzeFoodText(
          productInfo.descriptionForAI,
        );

        if (!mounted) return;

        // Update food item with product image if available
        final updatedFoodItem = productInfo.imageUrl != null
            ? foodItem.copyWith(imagePath: productInfo.imageUrl)
            : foodItem;

        // Add to meal
        final mealType = widget.mealType ?? MealType.lunch;
        await ref
            .read(foodLogProvider.notifier)
            .addFoodToMeal(mealType, updatedFoodItem);

        // Trigger health score recalculation
        ref.read(healthScoreProvider.notifier).recalculateScore();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added ${updatedFoodItem.name}'),
              backgroundColor: AppColors.success,
            ),
          );

          // Navigate to food detail
          context.pop();
          context.push(
            '${AppRoutes.foodDetail}/${updatedFoodItem.id}',
            extra: {'food': updatedFoodItem, 'mealType': mealType},
          );
        }
      } catch (e) {
        if (mounted) {
          _showAnalysisErrorDialog(productInfo.fullName);
        }
      }
    } else {
      // Product not found - show dialog
      _showNotFoundDialog(barcode);
    }
  }

  void _showAnalysisErrorDialog(String productName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.error_outline,
                color: AppColors.error,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Analysis Failed', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
        content: Text(
          'Could not analyze "$productName". Would you like to try again or use the camera instead?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetScanner();
            },
            child: const Text('Try Again'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              context.pop(); // Close barcode screen
              context.push(
                AppRoutes.camera,
                extra: {'mealType': widget.mealType},
              );
            },
            icon: const Icon(Icons.camera_alt, size: 18),
            label: const Text('Use Camera'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showNotFoundDialog(String barcode) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.search_off,
                color: AppColors.warning,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Product Not Found', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This product isn\'t in our database yet.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.camera_alt, color: AppColors.primary),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Snap a photo of the nutrition label instead?',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetScanner();
            },
            child: const Text('Try Again'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              context.pop(); // Close barcode screen
              context.push(
                AppRoutes.camera,
                extra: {'mealType': widget.mealType},
              );
            },
            icon: const Icon(Icons.camera_alt, size: 18),
            label: const Text('Use Camera'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _resetScanner() {
    setState(() {
      _isProcessing = false;
      _hasScanned = false;
      _lastScannedBarcode = null;
      _statusMessage = null;
    });
    _controller.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scan Barcode'),
        actions: [
          IconButton(
            onPressed: () => _controller.toggleTorch(),
            icon: ValueListenableBuilder(
              valueListenable: _controller,
              builder: (context, state, child) {
                return Icon(
                  state.torchState == TorchState.on
                      ? Icons.flash_on
                      : Icons.flash_off,
                );
              },
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera preview
          MobileScanner(controller: _controller, onDetect: _onBarcodeDetected),

          // Scan overlay
          Center(
            child: Container(
              width: 280,
              height: 160,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _isProcessing ? AppColors.success : AppColors.primary,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),

          // Instructions
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    _isProcessing
                        ? (_statusMessage ?? 'Looking up product...')
                        : 'Position barcode within the frame',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                if (_isProcessing)
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
              ],
            ),
          ),

          // Meal type indicator
          Positioned(
            top: 20,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    (widget.mealType ?? MealType.lunch).emoji,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    (widget.mealType ?? MealType.lunch).displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
