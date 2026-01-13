import 'package:adapty_flutter/adapty_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Subscription status enum
enum SubscriptionStatus { free, premium }

/// Free tier limits
class FreeTierLimits {
  static const int maxAIScans = 2;
  static const int maxChatMessages = 3;
}

/// User subscription state
class SubscriptionState {
  final SubscriptionStatus status;
  final int aiScansUsed;
  final int chatMessagesUsed;
  final DateTime? premiumExpiresAt;
  final bool isLoading;

  const SubscriptionState({
    this.status = SubscriptionStatus.free,
    this.aiScansUsed = 0,
    this.chatMessagesUsed = 0,
    this.premiumExpiresAt,
    this.isLoading = false,
  });

  bool get isPremium => status == SubscriptionStatus.premium;

  bool get canUseAIScan => isPremium || aiScansUsed < FreeTierLimits.maxAIScans;

  bool get canUseChat =>
      isPremium || chatMessagesUsed < FreeTierLimits.maxChatMessages;

  int get remainingAIScans =>
      isPremium ? -1 : FreeTierLimits.maxAIScans - aiScansUsed;

  int get remainingChatMessages =>
      isPremium ? -1 : FreeTierLimits.maxChatMessages - chatMessagesUsed;

  SubscriptionState copyWith({
    SubscriptionStatus? status,
    int? aiScansUsed,
    int? chatMessagesUsed,
    DateTime? premiumExpiresAt,
    bool clearExpiresAt = false, // Flag to explicitly clear the expiry date
    bool? isLoading,
  }) {
    return SubscriptionState(
      status: status ?? this.status,
      aiScansUsed: aiScansUsed ?? this.aiScansUsed,
      chatMessagesUsed: chatMessagesUsed ?? this.chatMessagesUsed,
      premiumExpiresAt: clearExpiresAt
          ? null
          : (premiumExpiresAt ?? this.premiumExpiresAt),
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Subscription service using Adapty
class SubscriptionService {
  static const String _adaptyPublicKey =
      'public_live_wBxj5qxJ.IgwcePBPSi3GH1RahKvo';
  static const String _paywallPlacementId = 'floating_button';

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static bool _isInitialized = false;

  /// Initialize Adapty SDK
  static Future<void> init() async {
    if (_isInitialized) return;

    try {
      await Adapty().activate(
        configuration: AdaptyConfiguration(apiKey: _adaptyPublicKey)
          ..withLogLevel(AdaptyLogLevel.verbose)
          ..withObserverMode(false),
      );

      _isInitialized = true;
      debugPrint('[SubscriptionService] Adapty initialized successfully');

      // Identify user if logged in
      final user = _auth.currentUser;
      if (user != null) {
        await identifyUser(user.uid);
      }
    } catch (e) {
      debugPrint('[SubscriptionService] Failed to initialize Adapty: $e');
    }
  }

  /// Identify user with Adapty
  static Future<void> identifyUser(String userId) async {
    try {
      await Adapty().identify(userId);
      debugPrint('[SubscriptionService] User identified: $userId');
    } catch (e) {
      debugPrint('[SubscriptionService] Failed to identify user: $e');
    }
  }

  /// Logout user from Adapty
  static Future<void> logout() async {
    try {
      await Adapty().logout();
      debugPrint('[SubscriptionService] User logged out from Adapty');
    } catch (e) {
      debugPrint('[SubscriptionService] Failed to logout from Adapty: $e');
    }
  }

  /// Get paywall for premium subscription
  static Future<AdaptyPaywall?> getPaywall() async {
    try {
      final paywall = await Adapty().getPaywall(
        placementId: _paywallPlacementId,
      );
      debugPrint('[SubscriptionService] Paywall loaded: ${paywall.name}');
      return paywall;
    } catch (e) {
      debugPrint('[SubscriptionService] Failed to get paywall: $e');
      return null;
    }
  }

  /// Get paywall products
  static Future<List<AdaptyPaywallProduct>> getPaywallProducts(
    AdaptyPaywall paywall,
  ) async {
    try {
      final products = await Adapty().getPaywallProducts(paywall: paywall);
      debugPrint('[SubscriptionService] Products loaded: ${products.length}');
      return products;
    } catch (e) {
      debugPrint('[SubscriptionService] Failed to get products: $e');
      return [];
    }
  }

  /// Make a purchase
  static Future<AdaptyPurchaseResult?> makePurchase(
    AdaptyPaywallProduct product,
  ) async {
    try {
      final result = await Adapty().makePurchase(product: product);
      debugPrint('[SubscriptionService] Purchase successful');
      return result;
    } catch (e) {
      debugPrint('[SubscriptionService] Purchase failed: $e');
      rethrow;
    }
  }

  /// Restore purchases
  static Future<AdaptyProfile?> restorePurchases() async {
    try {
      final profile = await Adapty().restorePurchases();
      debugPrint('[SubscriptionService] Purchases restored');
      return profile;
    } catch (e) {
      debugPrint('[SubscriptionService] Failed to restore purchases: $e');
      rethrow;
    }
  }

  /// Check if user has active premium subscription
  static Future<bool> checkPremiumStatus() async {
    try {
      final profile = await Adapty().getProfile();
      final hasActivePremium =
          profile.accessLevels['premium']?.isActive ?? false;
      debugPrint('[SubscriptionService] Premium status: $hasActivePremium');
      return hasActivePremium;
    } catch (e) {
      debugPrint('[SubscriptionService] Failed to check premium status: $e');
      return false;
    }
  }

  /// Get user's Adapty profile
  static Future<AdaptyProfile?> getProfile() async {
    try {
      return await Adapty().getProfile();
    } catch (e) {
      debugPrint('[SubscriptionService] Failed to get profile: $e');
      return null;
    }
  }

  // ============ FIRESTORE USAGE TRACKING ============

  /// Get user document reference
  static DocumentReference<Map<String, dynamic>> _userDoc(String userId) {
    return _firestore.collection('users').doc(userId);
  }

  /// Initialize subscription data for new user
  static Future<void> initUserSubscription(String userId) async {
    try {
      await _userDoc(userId).set({
        'subscription': {
          'status': 'free',
          'aiScansUsed': 0,
          'chatMessagesUsed': 0,
          'premiumExpiresAt': null,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true));
      debugPrint(
        '[SubscriptionService] Initialized subscription for user: $userId',
      );
    } catch (e) {
      debugPrint('[SubscriptionService] Failed to init subscription: $e');
    }
  }

  /// Get subscription state from Firestore
  static Future<SubscriptionState> getSubscriptionState(String userId) async {
    try {
      final doc = await _userDoc(userId).get();
      final data = doc.data();

      if (data == null || data['subscription'] == null) {
        await initUserSubscription(userId);
        return const SubscriptionState();
      }

      final subscription = data['subscription'] as Map<String, dynamic>;
      final statusStr = subscription['status'] as String? ?? 'free';
      final status = statusStr == 'premium'
          ? SubscriptionStatus.premium
          : SubscriptionStatus.free;

      // Parse the expiry date from Firestore
      DateTime? expiresAt;
      final expiresAtData = subscription['premiumExpiresAt'];
      if (expiresAtData != null) {
        if (expiresAtData is Timestamp) {
          expiresAt = expiresAtData.toDate();
        }
      }

      debugPrint(
        '[SubscriptionService] Firestore state - status: $statusStr, aiScans: ${subscription['aiScansUsed']}, chatMessages: ${subscription['chatMessagesUsed']}, expiresAt: $expiresAt',
      );

      return SubscriptionState(
        status: status,
        aiScansUsed: subscription['aiScansUsed'] ?? 0,
        chatMessagesUsed: subscription['chatMessagesUsed'] ?? 0,
        premiumExpiresAt: expiresAt,
      );
    } catch (e) {
      debugPrint('[SubscriptionService] Failed to get subscription state: $e');
      return const SubscriptionState();
    }
  }

  /// Increment AI scan usage
  static Future<void> incrementAIScanUsage(String userId) async {
    try {
      await _userDoc(userId).update({
        'subscription.aiScansUsed': FieldValue.increment(1),
        'subscription.updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('[SubscriptionService] AI scan usage incremented');
    } catch (e) {
      debugPrint('[SubscriptionService] Failed to increment AI scan: $e');
    }
  }

  /// Increment chat message usage
  static Future<void> incrementChatUsage(String userId) async {
    try {
      await _userDoc(userId).update({
        'subscription.chatMessagesUsed': FieldValue.increment(1),
        'subscription.updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('[SubscriptionService] Chat usage incremented');
    } catch (e) {
      debugPrint('[SubscriptionService] Failed to increment chat: $e');
    }
  }

  /// Update subscription status to premium
  static Future<void> updateToPremium(
    String userId,
    DateTime? expiresAt,
  ) async {
    try {
      await _userDoc(userId).update({
        'subscription.status': 'premium',
        'subscription.premiumExpiresAt': expiresAt != null
            ? Timestamp.fromDate(expiresAt)
            : null,
        'subscription.updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('[SubscriptionService] Updated to premium');
    } catch (e) {
      debugPrint('[SubscriptionService] Failed to update to premium: $e');
    }
  }

  /// Update subscription status to free
  static Future<void> updateToFree(String userId) async {
    try {
      await _userDoc(userId).update({
        'subscription.status': 'free',
        'subscription.premiumExpiresAt': null,
        'subscription.updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('[SubscriptionService] Updated to free');
    } catch (e) {
      debugPrint('[SubscriptionService] Failed to update to free: $e');
    }
  }

  /// Sync subscription status with Adapty
  static Future<SubscriptionState> syncSubscriptionStatus(String userId) async {
    try {
      final isPremium = await checkPremiumStatus();
      final currentState = await getSubscriptionState(userId);

      debugPrint(
        '[SubscriptionService] Sync - isPremium: $isPremium, currentState: ${currentState.status}, firestoreExpiry: ${currentState.premiumExpiresAt}',
      );

      if (isPremium) {
        // Get expiry date from Adapty
        final profile = await getProfile();
        final adaptyExpiresAt = profile?.accessLevels['premium']?.expiresAt;
        debugPrint(
          '[SubscriptionService] Adapty expiresAt: $adaptyExpiresAt, isUtc: ${adaptyExpiresAt?.isUtc}',
        );

        if (currentState.status == SubscriptionStatus.free) {
          // User has premium in Adapty but not in Firestore - update
          await updateToPremium(userId, adaptyExpiresAt);
        } else if (adaptyExpiresAt != null &&
            adaptyExpiresAt != currentState.premiumExpiresAt) {
          // Already premium - update expiry date if changed
          await updateToPremium(userId, adaptyExpiresAt);
        }

        // Use the Adapty expiry date as the source of truth
        final finalExpiresAt = adaptyExpiresAt ?? currentState.premiumExpiresAt;
        debugPrint(
          '[SubscriptionService] Final expiresAt for state: $finalExpiresAt, toLocal: ${finalExpiresAt?.toLocal()}',
        );

        return currentState.copyWith(
          status: SubscriptionStatus.premium,
          premiumExpiresAt: finalExpiresAt,
        );
      } else if (!isPremium &&
          currentState.status == SubscriptionStatus.premium) {
        // Premium expired in Adapty - update Firestore to free
        debugPrint('[SubscriptionService] Premium expired - reverting to free');
        await updateToFree(userId);
        return currentState.copyWith(
          status: SubscriptionStatus.free,
          clearExpiresAt: true, // Explicitly clear the expiry date
        );
      } else if (!isPremium && currentState.status == SubscriptionStatus.free) {
        // Already free - ensure Firestore is in sync
        if (currentState.premiumExpiresAt != null) {
          debugPrint(
            '[SubscriptionService] Free user has stale expiry date - clearing',
          );
          await updateToFree(userId);
          return currentState.copyWith(clearExpiresAt: true);
        }
      }

      // Return Firestore state as-is (for free users)
      return currentState;
    } catch (e) {
      debugPrint('[SubscriptionService] Failed to sync status: $e');
      // On error, return Firestore state
      try {
        return await getSubscriptionState(userId);
      } catch (_) {
        return const SubscriptionState();
      }
    }
  }
}

/// Subscription state notifier
class SubscriptionNotifier extends StateNotifier<SubscriptionState> {
  SubscriptionNotifier() : super(const SubscriptionState(isLoading: true)) {
    _init();
  }

  Future<void> _init() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await loadSubscription(user.uid);
    } else {
      state = const SubscriptionState();
    }
  }

  /// Load subscription state
  Future<void> loadSubscription(String userId) async {
    state = state.copyWith(isLoading: true);

    try {
      // Initialize Adapty if not already
      await SubscriptionService.init();
      await SubscriptionService.identifyUser(userId);

      // Sync with Adapty and get current state
      final subscriptionState =
          await SubscriptionService.syncSubscriptionStatus(userId);
      state = subscriptionState.copyWith(isLoading: false);
    } catch (e) {
      debugPrint('[SubscriptionNotifier] Failed to load subscription: $e');
      state = const SubscriptionState(isLoading: false);
    }
  }

  /// Refresh subscription state
  Future<void> refresh() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await loadSubscription(user.uid);
    }
  }

  /// Record AI scan usage
  Future<bool> recordAIScanUsage() async {
    if (!state.canUseAIScan) {
      return false;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    if (!state.isPremium) {
      await SubscriptionService.incrementAIScanUsage(user.uid);
      state = state.copyWith(aiScansUsed: state.aiScansUsed + 1);
    }

    return true;
  }

  /// Record chat message usage
  Future<bool> recordChatUsage() async {
    if (!state.canUseChat) {
      return false;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    if (!state.isPremium) {
      await SubscriptionService.incrementChatUsage(user.uid);
      state = state.copyWith(chatMessagesUsed: state.chatMessagesUsed + 1);
    }

    return true;
  }

  /// Handle successful purchase
  Future<void> handlePurchaseSuccess() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await loadSubscription(user.uid);
    }
  }

  /// Logout - reset state
  void logout() {
    SubscriptionService.logout();
    state = const SubscriptionState();
  }
}

/// Provider for subscription state
final subscriptionProvider =
    StateNotifierProvider<SubscriptionNotifier, SubscriptionState>((ref) {
      return SubscriptionNotifier();
    });

/// Provider for checking if user can use AI features
final canUseAIProvider = Provider<bool>((ref) {
  final subscription = ref.watch(subscriptionProvider);
  return subscription.canUseAIScan;
});

/// Provider for checking if user can use chat
final canUseChatProvider = Provider<bool>((ref) {
  final subscription = ref.watch(subscriptionProvider);
  return subscription.canUseChat;
});
