import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/router/app_router.dart';
import '../../../core/providers/user_provider.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

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
        icon: Image.network(
          'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
          width: 24,
          height: 24,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.g_mobiledata, size: 24),
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

        // Sync local profile data to Firestore after login
        await ref.read(userProfileProvider.notifier).syncToFirestore();
      } else {
        await FirebaseService.signUpWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        // Update display name
        if (_nameController.text.isNotEmpty) {
          await FirebaseService.updateDisplayName(_nameController.text.trim());
        }

        // Sync local profile data to Firestore for new user
        await ref.read(userProfileProvider.notifier).syncToFirestore();
      }

      if (mounted) {
        // Navigate to home
        context.go(AppRoutes.home);
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
        // Sync local profile data to Firestore (works for both new and existing users)
        await ref.read(userProfileProvider.notifier).syncToFirestore();

        // Navigate to home
        context.go(AppRoutes.home);
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

  Future<void> _saveOnboardingData(String userId) async {
    final userProfile = ref.read(userProfileProvider);

    if (userProfile != null) {
      await FirebaseService.saveUserData(
        userId: userId,
        profile: {
          'age': userProfile.age,
          'gender': userProfile.gender,
          'heightCm': userProfile.heightCm,
          'weightKg': userProfile.weightKg,
        },
        goals: {
          'type': userProfile.goal,
          'targetWeightKg': userProfile.weightKg, // Can be updated later
          'weeklyGoalKg': 0.5,
        },
        health: {
          'conditions': {
            'bp': userProfile.healthConditions.contains('high_blood_pressure'),
            'pcos': userProfile.healthConditions.contains('pcos'),
            'diabetes': userProfile.healthConditions.contains('diabetes'),
            'cholesterol': userProfile.healthConditions.contains(
              'high_cholesterol',
            ),
          },
        },
        preferences: {
          'dietType': userProfile.dietaryPreferences,
          'cuisine': [userProfile.country.toLowerCase()],
          'mealCountPerDay': 3,
        },
        plan: {
          'dailyCalories': userProfile.dailyCalorieTarget.toInt(),
          'macros': {
            'protein': userProfile.macroTargets.proteinGrams.toInt(),
            'carbs': userProfile.macroTargets.carbsGrams.toInt(),
            'fat': userProfile.macroTargets.fatGrams.toInt(),
            'fiber': 30,
          },
          'sodiumLimitMg': 2300,
          'giLimit': 55,
        },
      );
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
      return 'No account found with this email';
    } else if (errorStr.contains('wrong-password')) {
      return 'Incorrect password';
    } else if (errorStr.contains('email-already-in-use')) {
      return 'An account already exists with this email';
    } else if (errorStr.contains('weak-password')) {
      return 'Password is too weak';
    } else if (errorStr.contains('invalid-email')) {
      return 'Invalid email address';
    } else if (errorStr.contains('network')) {
      return 'Network error. Please check your connection';
    } else if (errorStr.contains('too-many-requests')) {
      return 'Too many attempts. Please try again later';
    }

    return 'An error occurred. Please try again';
  }
}
