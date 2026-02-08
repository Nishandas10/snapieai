import 'package:adapty_flutter/adapty_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/services/subscription_service.dart';

/// Paywall shown to first-time users right after onboarding.
/// Emphasises 3-day free trial, cancel-anytime, and shows
/// Monthly / Quarterly / Annual plans.
class OnboardingPaywallScreen extends ConsumerStatefulWidget {
  const OnboardingPaywallScreen({super.key});

  @override
  ConsumerState<OnboardingPaywallScreen> createState() =>
      _OnboardingPaywallScreenState();
}

class _OnboardingPaywallScreenState
    extends ConsumerState<OnboardingPaywallScreen> {
  List<AdaptyPaywallProduct> _products = [];
  bool _isLoading = true;
  bool _isPurchasing = false;
  String? _error;
  int _selectedProductIndex = -1; // -1 means nothing selected yet
  double? _monthlyPricePerMonth; // Used for discount calculation

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

        // Keep only monthly, quarterly and yearly – drop weekly
        final filteredProducts = allProducts.where((product) {
          final sub = product.subscription;
          if (sub == null) return false;
          final period = sub.period;
          if (period.unit == AdaptyPeriodUnit.week) return false;
          return true;
        }).toList();

        // Sort: monthly first, then quarterly, then yearly (shortest first)
        filteredProducts.sort((a, b) {
          final aDays = _periodToDays(a.subscription!.period);
          final bDays = _periodToDays(b.subscription!.period);
          return aDays.compareTo(bDays);
        });

        // Find monthly price for discount calculation
        double? monthlyPrice;
        for (final product in filteredProducts) {
          final sub = product.subscription;
          if (sub != null &&
              sub.period.unit == AdaptyPeriodUnit.month &&
              sub.period.numberOfUnits == 1) {
            monthlyPrice = product.price.amount;
            break;
          }
        }

        setState(() {
          _products = filteredProducts;
          _monthlyPricePerMonth = monthlyPrice;
          // Pre-select quarterly if present, otherwise yearly
          _selectedProductIndex = _findDefaultIndex(filteredProducts);
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
        _error = 'Failed to load subscription options';
        _isLoading = false;
      });
    }
  }

  int _periodToDays(AdaptySubscriptionPeriod period) {
    switch (period.unit) {
      case AdaptyPeriodUnit.day:
        return period.numberOfUnits;
      case AdaptyPeriodUnit.week:
        return period.numberOfUnits * 7;
      case AdaptyPeriodUnit.month:
        return period.numberOfUnits * 30;
      case AdaptyPeriodUnit.year:
        return period.numberOfUnits * 365;
      default:
        return 0;
    }
  }

  bool _isQuarterly(AdaptyPaywallProduct product) {
    final sub = product.subscription;
    if (sub == null) return false;
    // Check by period (3 months) or by vendor product id
    if (sub.period.unit == AdaptyPeriodUnit.month &&
        sub.period.numberOfUnits == 3) {
      return true;
    }
    if (product.vendorProductId.toLowerCase().contains('quarterly')) {
      return true;
    }
    return false;
  }

  /// Calculates discount percentage compared to monthly plan
  int? _calculateDiscount(AdaptyPaywallProduct product) {
    if (_monthlyPricePerMonth == null || _monthlyPricePerMonth! <= 0) {
      return null;
    }

    final sub = product.subscription;
    if (sub == null) return null;

    final totalPrice = product.price.amount;
    final period = sub.period;
    int months;

    switch (period.unit) {
      case AdaptyPeriodUnit.month:
        months = period.numberOfUnits;
        break;
      case AdaptyPeriodUnit.year:
        months = period.numberOfUnits * 12;
        break;
      default:
        return null;
    }

    if (months <= 1) return null; // No discount for monthly

    final equivalentMonthlyTotal = _monthlyPricePerMonth! * months;
    if (equivalentMonthlyTotal <= 0) return null;

    final savings = equivalentMonthlyTotal - totalPrice;
    final discountPercent = (savings / equivalentMonthlyTotal * 100).round();

    return discountPercent > 0 ? discountPercent : null;
  }

  int _findDefaultIndex(List<AdaptyPaywallProduct> products) {
    // Try to find quarterly first
    for (int i = 0; i < products.length; i++) {
      if (_isQuarterly(products[i])) {
        return i;
      }
    }
    // Fallback to yearly
    for (int i = 0; i < products.length; i++) {
      final sub = products[i].subscription;
      if (sub != null && sub.period.unit == AdaptyPeriodUnit.year) {
        return i;
      }
    }
    return products.isNotEmpty ? 0 : -1;
  }

  Future<void> _makePurchase() async {
    if (_products.isEmpty || _isPurchasing || _selectedProductIndex < 0) return;

    setState(() => _isPurchasing = true);

    try {
      final product = _products[_selectedProductIndex];
      await SubscriptionService.makePurchase(product);

      // Refresh subscription state
      await ref.read(subscriptionProvider.notifier).handlePurchaseSuccess();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Welcome! Your 3-day free trial has started.'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop(true);
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

  // ──────────────────── UI ────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Close / Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: GestureDetector(
                  onTap: () => context.pop(false),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
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
          // ── Hero illustration ──
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              size: 52,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),

          // ── Title ──
          const Text(
            'Try Premium Free\nfor 3 Days',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Unlock everything. Cancel anytime.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 28),

          // ── Features ──
          _buildFeaturesList(),
          const SizedBox(height: 28),

          // ── Plan cards ──
          if (_products.isNotEmpty) ...[
            ..._products.asMap().entries.map((entry) {
              return _buildPlanCard(entry.value, entry.key);
            }),
            const SizedBox(height: 24),

            // ── CTA button ──
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
                        'Start Free Trial',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 14),

            // ── Restore ──
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
            const SizedBox(height: 4),

            // ── Legal fine print ──
            const Text(
              'Auto-renewable subscription. Cancel anytime from your device settings. '
              'Payment will be charged to your account after the 3-day free trial. '
              'Subscription automatically renews unless cancelled at least 24 hours before the end of the current period.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: AppColors.textHint),
            ),
            const SizedBox(height: 32),
          ],
        ],
      ),
    );
  }

  // ──────────────────── Features list ────────────────────

  Widget _buildFeaturesList() {
    const features = [
      ('📸', 'Unlimited AI Food Scans'),
      ('🤖', 'Unlimited Sara AI Chat'),
      ('🎯', 'Personalized Meal Plans'),
      ('📊', 'Advanced Nutrition Analytics'),
      ('🔔', 'Smart Meal Reminders'),
    ];

    return Column(
      children: features
          .map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Text(f.$1, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      f.$2,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.success,
                    size: 22,
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  // ──────────────────── Plan card ────────────────────

  Widget _buildPlanCard(AdaptyPaywallProduct product, int index) {
    final isSelected = index == _selectedProductIndex;
    final price = product.price.localizedString ?? 'N/A';
    final priceAmount = product.price.amount;
    final subscription = product.subscription!;
    final period = subscription.period;
    final isQuarterly = _isQuarterly(product);
    final discount = _calculateDiscount(product);

    String label;
    String subLabel = '';
    String pricePerMonthText = '';
    bool isBestValue = false;
    bool isMostPopular = false;
    bool isMonthly = false;

    switch (period.unit) {
      case AdaptyPeriodUnit.month:
        if (isQuarterly) {
          label = 'Quarterly';
          isMostPopular = true; // Quarterly is MOST POPULAR
          // Calculate per month price
          final perMonth = priceAmount / 3;
          pricePerMonthText =
              '${_formatPrice(perMonth, product.price.currencyCode)}/mo';
          subLabel = discount != null && discount > 0
              ? 'Save $discount% • Billed quarterly'
              : 'Billed quarterly';
        } else if (period.numberOfUnits == 1) {
          label = 'Monthly';
          isMonthly = true;
          subLabel = 'EARLY BIRD OFFER';
        } else {
          label = '${period.numberOfUnits} Months';
          subLabel = '';
        }
        break;
      case AdaptyPeriodUnit.year:
        label = 'Annual';
        isBestValue = true; // Annual is BEST VALUE
        // Calculate per month price
        final perMonth = priceAmount / 12;
        pricePerMonthText =
            '${_formatPrice(perMonth, product.price.currencyCode)}/mo';
        subLabel = discount != null && discount > 0
            ? 'Save $discount% • Billed annually'
            : 'Billed annually';
        break;
      default:
        label = 'Subscription';
        subLabel = '';
    }

    return GestureDetector(
      onTap: () => setState(() => _selectedProductIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
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
                    color: AppColors.primary.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Radio indicator
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
            const SizedBox(width: 14),

            // Label + sub-label
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        label,
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
                            color: AppColors.success,
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
                      if (isMostPopular) ...[
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
                            'MOST POPULAR',
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
                  if (isMonthly) ...[
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        subLabel,
                        style: TextStyle(
                          color: AppColors.warning,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  if (!isMonthly && subLabel.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Price
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (pricePerMonthText.isNotEmpty) ...[
                  Text(
                    pricePerMonthText,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    price,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ] else ...[
                  Text(
                    price,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Text(
                    '/month',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Format price with currency
  String _formatPrice(double amount, String? currencyCode) {
    // Round to 2 decimal places
    final rounded = (amount * 100).round() / 100;
    final currency = currencyCode ?? 'USD';

    // Common currency symbols
    final symbols = {
      'USD': '\$',
      'EUR': '€',
      'GBP': '£',
      'INR': '₹',
      'JPY': '¥',
      'CNY': '¥',
      'KRW': '₩',
      'AUD': 'A\$',
      'CAD': 'CA\$',
    };

    final symbol = symbols[currency] ?? '$currency ';
    return '$symbol${rounded.toStringAsFixed(2)}';
  }
}
