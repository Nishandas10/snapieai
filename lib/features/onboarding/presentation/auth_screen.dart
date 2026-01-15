import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/services/subscription_service.dart';
import '../../../core/router/app_router.dart';
import '../../../core/providers/user_provider.dart';

class AuthScreen extends ConsumerStatefulWidget {
  final bool initialShowLogin;

  const AuthScreen({super.key, this.initialShowLogin = true});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  late bool _isLogin;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _isLogin = widget.initialShowLogin;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),

              // Header
              _buildHeader(),
              const SizedBox(height: 40),

              // Error message
              if (_errorMessage != null) ...[
                _buildErrorMessage(),
                const SizedBox(height: 16),
              ],

              // Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Name field (only for sign up)
                    if (!_isLogin) ...[
                      _buildNameField(),
                      const SizedBox(height: 16),
                    ],

                    // Email field
                    _buildEmailField(),
                    const SizedBox(height: 16),

                    // Password field
                    _buildPasswordField(),
                    const SizedBox(height: 24),

                    // Submit button
                    _buildSubmitButton(),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Or divider
              _buildDivider(),
              const SizedBox(height: 24),

              // Google sign in
              _buildGoogleButton(),
              const SizedBox(height: 24),

              // Toggle login/signup
              _buildToggleButton(),

              // Forgot password
              if (_isLogin) ...[
                const SizedBox(height: 16),
                _buildForgotPasswordButton(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.restaurant_menu,
            color: Colors.white,
            size: 40,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          _isLogin ? 'Welcome Back!' : 'Create Account',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          _isLogin
              ? 'Sign in to continue your nutrition journey'
              : 'Start your personalized nutrition journey',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(color: AppColors.error, fontSize: 13),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => setState(() => _errorMessage = null),
            color: AppColors.error,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: InputDecoration(
        labelText: 'Full Name',
        hintText: 'Enter your name',
        prefixIcon: const Icon(Icons.person_outline),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      textCapitalization: TextCapitalization.words,
      validator: (value) {
        if (!_isLogin && (value == null || value.trim().isEmpty)) {
          return 'Please enter your name';
        }
        return null;
      },
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      decoration: InputDecoration(
        labelText: 'Email',
        hintText: 'Enter your email',
        prefixIcon: const Icon(Icons.email_outlined),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      keyboardType: TextInputType.emailAddress,
      autocorrect: false,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your email';
        }
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
          return 'Please enter a valid email';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      decoration: InputDecoration(
        labelText: 'Password',
        hintText: 'Enter your password',
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      obscureText: _obscurePassword,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your password';
        }
        if (!_isLogin && value.length < 6) {
          return 'Password must be at least 6 characters';
        }
        return null;
      },
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        onPressed: _isLoading ? null : _handleEmailAuth,
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                _isLogin ? 'Sign In' : 'Create Account',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('or', style: TextStyle(color: AppColors.textSecondary)),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton.icon(
        onPressed: _isLoading ? null : _handleGoogleSignIn,
        icon: SvgPicture.asset(
          'assets/icons/google_logo.svg',
          width: 24,
          height: 24,
        ),
        label: const Text(
          'Continue with Google',
          style: TextStyle(fontSize: 16),
        ),
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isLogin ? "Don't have an account? " : 'Already have an account? ',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              _isLogin = !_isLogin;
              _errorMessage = null;
            });
          },
          child: Text(_isLogin ? 'Sign Up' : 'Sign In'),
        ),
      ],
    );
  }

  Widget _buildForgotPasswordButton() {
    return Center(
      child: TextButton(
        onPressed: _handleForgotPassword,
        child: const Text('Forgot Password?'),
      ),
    );
  }

  Future<void> _handleEmailAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isLogin) {
        await FirebaseService.signInWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        // Check if user has profile data in Firestore
        final userId = FirebaseService.currentUser?.uid;
        if (userId != null) {
          // Initialize subscription for user
          await SubscriptionService.identifyUser(userId);
          await ref
              .read(subscriptionProvider.notifier)
              .loadSubscription(userId);

          final userData = await FirebaseService.getUserData(userId);

          if (userData != null && userData['profile'] != null) {
            // User has profile data, sync from Firestore and go to home
            await ref.read(userProfileProvider.notifier).syncFromFirestore();
            if (mounted) {
              context.go(AppRoutes.home);
            }
          } else {
            // User logged in but no profile data in Firestore
            // Check if they have local onboarding data to sync
            final localProfile = ref.read(userProfileProvider);
            if (localProfile != null && localProfile.id.isNotEmpty) {
              // Sync local onboarding data to Firestore
              await ref.read(userProfileProvider.notifier).syncToFirestore();
              await SubscriptionService.initUserSubscription(userId);
              if (mounted) {
                context.go(AppRoutes.home);
              }
            } else {
              // No local data either, go to onboarding
              await SubscriptionService.initUserSubscription(userId);
              if (mounted) {
                context.go(AppRoutes.profileSetup);
              }
            }
          }
        }
      } else {
        await FirebaseService.signUpWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        // Update display name
        if (_nameController.text.isNotEmpty) {
          await FirebaseService.updateDisplayName(_nameController.text.trim());
        }

        // New user - initialize subscription data
        final userId = FirebaseService.currentUser?.uid;
        if (userId != null) {
          await SubscriptionService.identifyUser(userId);
          await SubscriptionService.initUserSubscription(userId);
          await ref
              .read(subscriptionProvider.notifier)
              .loadSubscription(userId);

          // Check if user has local onboarding data to sync
          final localProfile = ref.read(userProfileProvider);
          if (localProfile != null && localProfile.id.isNotEmpty) {
            // Sync local onboarding data to Firestore
            await ref.read(userProfileProvider.notifier).syncToFirestore();
            if (mounted) {
              context.go(AppRoutes.home);
            }
          } else {
            // No local data, go to onboarding
            if (mounted) {
              context.go(AppRoutes.profileSetup);
            }
          }
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = _getErrorMessage(e);
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final credential = await FirebaseService.signInWithGoogle();

      if (credential != null && mounted) {
        // Check if user has profile data in Firestore
        final userId = FirebaseService.currentUser?.uid;
        if (userId != null) {
          // Initialize subscription for user
          await SubscriptionService.identifyUser(userId);
          await ref
              .read(subscriptionProvider.notifier)
              .loadSubscription(userId);

          final userData = await FirebaseService.getUserData(userId);

          if (userData != null && userData['profile'] != null) {
            // User has profile data, sync from Firestore and go to home
            await ref.read(userProfileProvider.notifier).syncFromFirestore();
            if (mounted) {
              context.go(AppRoutes.home);
            }
          } else {
            // User signed in but no profile data in Firestore
            // Check if they have local onboarding data to sync
            final localProfile = ref.read(userProfileProvider);
            if (localProfile != null && localProfile.id.isNotEmpty) {
              // Sync local onboarding data to Firestore
              await ref.read(userProfileProvider.notifier).syncToFirestore();
              await SubscriptionService.initUserSubscription(userId);
              if (mounted) {
                context.go(AppRoutes.home);
              }
            } else {
              // No local data either, go to onboarding
              await SubscriptionService.initUserSubscription(userId);
              if (mounted) {
                context.go(AppRoutes.profileSetup);
              }
            }
          }
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = _getErrorMessage(e);
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your email address first';
      });
      return;
    }

    try {
      await FirebaseService.sendPasswordResetEmail(email);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password reset email sent to $email'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = _getErrorMessage(e);
      });
    }
  }

  String _getErrorMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('user-not-found')) {
      return 'No account found with this email. Please sign up first.';
    } else if (errorStr.contains('wrong-password') ||
        errorStr.contains('invalid-credential')) {
      return 'Incorrect email or password. Please try again.';
    } else if (errorStr.contains('email-already-in-use')) {
      return 'An account already exists with this email. Please sign in instead.';
    } else if (errorStr.contains('weak-password')) {
      return 'Password is too weak. Use at least 6 characters.';
    } else if (errorStr.contains('invalid-email')) {
      return 'Please enter a valid email address.';
    } else if (errorStr.contains('network')) {
      return 'Network error. Please check your internet connection.';
    } else if (errorStr.contains('too-many-requests')) {
      return 'Too many failed attempts. Please try again later.';
    } else if (errorStr.contains('user-disabled')) {
      return 'This account has been disabled. Please contact support.';
    } else if (errorStr.contains('operation-not-allowed')) {
      return 'This sign-in method is not enabled. Please try another method.';
    } else if (errorStr.contains('account-exists-with-different-credential')) {
      return 'An account already exists with a different sign-in method.';
    } else if (errorStr.contains('requires-recent-login')) {
      return 'Please sign in again to complete this action.';
    } else if (errorStr.contains('popup-closed-by-user') ||
        errorStr.contains('cancelled')) {
      return 'Sign in was cancelled. Please try again.';
    }

    return 'Something went wrong. Please try again.';
  }
}
