import 'package:adapty_flutter/adapty_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/services/subscription_service.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  final String? featureType; // 'camera', 'ai_text', 'chat'

  const PaywallScreen({super.key, this.featureType});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  List<AdaptyPaywallProduct> _products = [];
  bool _isLoading = true;
  bool _isPurchasing = false;
  String? _error;
  int _selectedProductIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadPaywall();
  }

  Future<void> _loadPaywall() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final paywall = await SubscriptionService.getPaywall();
      if (paywall != null) {
        final allProducts = await SubscriptionService.getPaywallProducts(
          paywall,
        );

        // Filter out weekly subscriptions, keep only monthly and yearly
        final filteredProducts = allProducts.where((product) {
          final subscription = product.subscription;
          if (subscription == null)
            return true; // Keep non-subscription products

          final period = subscription.period;
          // Exclude weekly (period.unit == week)
          return period.unit != AdaptyPeriodUnit.week;
        }).toList();

        setState(() {
          _products = filteredProducts;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Unable to load subscription options';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load subscription options: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _makePurchase() async {
    if (_products.isEmpty || _isPurchasing) return;

    setState(() => _isPurchasing = true);

    try {
      final product = _products[_selectedProductIndex];
      await SubscriptionService.makePurchase(product);

      // Refresh subscription state
      await ref.read(subscriptionProvider.notifier).handlePurchaseSuccess();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Welcome to Premium! Enjoy unlimited access.'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop(true); // Return true to indicate purchase success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPurchasing = false);
      }
    }
  }

  Future<void> _restorePurchases() async {
    setState(() => _isPurchasing = true);

    try {
      await SubscriptionService.restorePurchases();
      await ref.read(subscriptionProvider.notifier).handlePurchaseSuccess();

      final subscription = ref.read(subscriptionProvider);

      if (mounted) {
        if (subscription.isPremium) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Purchases restored successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
          context.pop(true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No previous purchases found'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restore failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPurchasing = false);
      }
    }
  }

  String _getHeaderTitle() {
    switch (widget.featureType) {
      case 'camera':
        return 'Unlock AI Food Scanner';
      case 'ai_text':
        return 'Unlock AI Analysis';
      case 'chat':
        return 'Unlock Sara AI Assistant';
      default:
        return 'Upgrade to Premium';
    }
  }

  String _getHeaderSubtitle() {
    final subscription = ref.read(subscriptionProvider);
    switch (widget.featureType) {
      case 'camera':
        return 'You\'ve used all ${FreeTierLimits.maxAIScans} free AI scans';
      case 'ai_text':
        return 'You\'ve used all ${FreeTierLimits.maxAIScans} free AI analyses';
      case 'chat':
        return 'You\'ve used all ${FreeTierLimits.maxChatMessages} free chat messages';
      default:
        if (!subscription.canUseAIScan) {
          return 'AI scans limit reached';
        } else if (!subscription.canUseChat) {
          return 'Chat messages limit reached';
        }
        return 'Get unlimited access to all features';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Close button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: IconButton(
                  onPressed: () => context.pop(false),
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.cardBackground,
                    shape: const CircleBorder(),
                  ),
                ),
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? _buildErrorState()
                  : _buildPaywallContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadPaywall,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaywallContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Premium badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star, color: Colors.white, size: 18),
                SizedBox(width: 6),
                Text(
                  'PREMIUM',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Header
          Text(
            _getHeaderTitle(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getHeaderSubtitle(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),

          // Features list
          _buildFeaturesList(),
          const SizedBox(height: 32),

          // Products
          if (_products.isNotEmpty) ...[
            ..._products.asMap().entries.map((entry) {
              return _buildProductCard(
                entry.value,
                entry.key,
                entry.key == _selectedProductIndex,
              );
            }),
            const SizedBox(height: 24),

            // Purchase button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isPurchasing ? null : _makePurchase,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isPurchasing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Start Premium',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Restore purchases
            TextButton(
              onPressed: _isPurchasing ? null : _restorePurchases,
              child: const Text(
                'Restore Purchases',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Terms
            Text(
              'Auto-renewable subscription. Cancel anytime.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textHint),
            ),
            const SizedBox(height: 32),
          ],
        ],
      ),
    );
  }

  Widget _buildFeaturesList() {
    final features = [
      _FeatureItem(
        icon: Icons.camera_alt,
        title: 'Unlimited AI Food Scans',
        description: 'Snap photos for instant nutrition analysis',
      ),
      _FeatureItem(
        icon: Icons.auto_awesome,
        title: 'Unlimited AI Text Analysis',
        description: 'Describe any food for AI-powered insights',
      ),
      _FeatureItem(
        icon: Icons.chat_bubble_outline,
        title: 'Unlimited Sara AI Chat',
        description: 'Get personalized nutrition advice 24/7',
      ),
      _FeatureItem(
        icon: Icons.restaurant_menu,
        title: 'Smart Meal Planning',
        description: 'AI-generated meal plans tailored to you',
      ),
      _FeatureItem(
        icon: Icons.insights,
        title: 'Advanced Analytics',
        description: 'Deep insights into your nutrition habits',
      ),
    ];

    return Column(
      children: features.map((feature) => _buildFeatureRow(feature)).toList(),
    );
  }

  Widget _buildFeatureRow(_FeatureItem feature) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(feature.icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  feature.description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: AppColors.success, size: 24),
        ],
      ),
    );
  }

  Widget _buildProductCard(
    AdaptyPaywallProduct product,
    int index,
    bool isSelected,
  ) {
    final price = product.price.localizedString ?? 'N/A';
    final subscription = product.subscription;
    String periodText = 'Subscription';
    String perPeriodText = '';
    bool isBestValue = index == 0; // First product is typically best value
    bool hasFreeTrial = false;

    if (subscription != null) {
      final period = subscription.period;
      switch (period.unit) {
        case AdaptyPeriodUnit.week:
          periodText = period.numberOfUnits == 1
              ? 'Weekly'
              : '${period.numberOfUnits} Weeks';
          perPeriodText = '/week';
          break;
        case AdaptyPeriodUnit.month:
          periodText = period.numberOfUnits == 1
              ? 'Monthly'
              : '${period.numberOfUnits} Months';
          perPeriodText = '/month';
          isBestValue = period.numberOfUnits > 1 || index == 0;
          break;
        case AdaptyPeriodUnit.year:
          periodText = period.numberOfUnits == 1
              ? 'Yearly'
              : '${period.numberOfUnits} Years';
          perPeriodText = '/year';
          isBestValue = true;
          break;
        default:
          periodText = 'Subscription';
          perPeriodText = '';
      }

      // Check for free trial
      final offer = subscription.offer;
      if (offer != null) {
        for (final phase in offer.phases) {
          if (phase.price.amount == 0) {
            hasFreeTrial = true;
            break;
          }
        }
      }
    }

    return GestureDetector(
      onTap: () => setState(() => _selectedProductIndex = index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        periodText,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (isBestValue) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'BEST VALUE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (hasFreeTrial)
                    Text(
                      'Free trial available',
                      style: TextStyle(fontSize: 12, color: AppColors.success),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  perPeriodText,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureItem {
  final IconData icon;
  final String title;
  final String description;

  _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });
}
